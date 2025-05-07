<?php
namespace App\Http\Controllers\API;
use Illuminate\Support\Facades\Log; 
use App\Models\Column;
use App\Http\Controllers\Controller;
use App\Models\Issue;
use App\Models\Notification;
use App\Models\Project;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class IssueController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        $projectId = $request->query('project_id');
        $columnId = $request->query('column_id');
        
        $query = Issue::query()->with('assignee', 'reporter', 'project', 'column');
        
        if ($projectId) {
            $query->where('project_id', $projectId);
        }
        
        if ($columnId) {
            $query->where('column_id', $columnId);
        }
        
        
        if ($user->isUser()) {
            $query->where(function($q) use ($user) {
                $q->where('reporter_id', $user->id)
                  ->orWhere('assignee_id', $user->id);
            });
        } elseif ($user->isAdmin()) {
            
            $projectIds = Project::where('direction', $user->direction)->pluck('id');
            $query->whereIn('project_id', $projectIds);
        }
        
        
        $issues = $query->get();
        
        return response()->json($issues);
    }
    public function store(Request $request)
{
    $user = $request->user();

    if ($user->isUser()) {
        $request->merge([
            'reporter_id' => $user->id,
            'assignee_id' => $user->id,
        ]);
    }

    $validator = Validator::make($request->all(), [
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'type' => 'required|in:task,bug,story,epic',
        'priority' => 'required|integer|between:1,3',
        'reporter_id' => 'required|exists:users,id',
        'assignee_id' => 'nullable|exists:users,id',
        'due_date' => 'nullable|date',
        'story_points' => 'nullable|integer',
        'project_id' => 'required|exists:projects,id',
        'column_id' => 'required|exists:columns,id',
        'deposit' => 'required|boolean',
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    $issue = Issue::create($request->all());

    
    if ($issue->assignee_id) {
        Notification::create([
            'user_id' => $issue->assignee_id,
            'title' => 'New Issue Assigned',
            'message' => 'You have been assigned to issue: ' . $issue->title,
            'data' => [
                'issue_id' => $issue->id,
                'project_id' => $issue->project_id,
            ],
        ]);
    }

    return response()->json($issue->load('assignee', 'reporter', 'project', 'column'), 201);
}
public function show(Request $request, $id)
{
    $user = $request->user();
    $issue = Issue::with('assignee', 'reporter', 'project', 'column', 'comments.user', 'attachments')
        ->findOrFail($id);

    
    if ($issue->column && $issue->column->name === 'to_do') {
        
        if ($issue->assignee_id === $user->id || $user->isAdmin() || $user->isSuperAdmin()) {
            $seenColumn = Column::firstOrCreate(
                [
                    'name' => 'seen',
                    'project_id' => $issue->project_id,
                    'board_id' => $issue->column->board_id ?? 1,
                ],
                ['position' => 1]
            );

            $issue->column_id = $seenColumn->id;
            $issue->save();

            
            $this->createStatusNotification($issue, 'seen', $user);

            
            $issue = $issue->fresh();
        }
    }

    return response()->json($issue->load('assignee', 'reporter', 'project', 'column', 'comments.user', 'attachments'));
}



    public function update(Request $request, $id)
{
    $user = $request->user();
    $issue = Issue::findOrFail($id);

    if ($user->isUser() && $issue->reporter_id !== $user->id && $issue->assignee_id !== $user->id) {
        return response()->json(['message' => 'Unauthorized'], 403);
    }

    $validator = Validator::make($request->all(), [
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'type' => 'required|in:task,bug,story,epic',
        'priority' => 'required|integer|between:1,3',
        'assignee_id' => 'nullable|exists:users,id',
        'due_date' => 'nullable|date',
        'story_points' => 'nullable|integer',
        'column_id' => 'required|exists:columns,id',
        'deposit' => 'required|boolean',
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    $oldAssigneeId = $issue->assignee_id;
    $issue->update($request->all());

    if ($request->assignee_id && $oldAssigneeId !== $request->assignee_id) {
        Notification::create([
            'user_id' => $request->assignee_id,
            'title' => 'Issue Assigned to You',
            'message' => 'You have been assigned to issue: ' . $issue->title,
            'data' => [
                'issue_id' => $issue->id,
                'project_id' => $issue->project_id,
            ],
        ]);
    }

    return response()->json($issue->load('assignee', 'reporter', 'project', 'column'));
}

    public function destroy($id)
    {
        $issue = Issue::findOrFail($id);
        
        
        if ($issue->deposit) {
            return response()->json(['message' => 'Cannot delete deposited issues'], 422);
        }
        
        $issue->delete();
        
        return response()->json(null, 204);
    }

    public function updateColumn(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'column_id' => 'required|exists:columns,id',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $issue = Issue::findOrFail($id);
        $issue->column_id = $request->column_id;
        $issue->save();
        
        
        if ($issue->assignee_id) {
            Notification::create([
                'user_id' => $issue->assignee_id,
                'title' => 'Issue Status Changed',
                'message' => 'Issue "' . $issue->title . '" has been moved to a new status',
                'data' => [
                    'issue_id' => $issue->id,
                    'project_id' => $issue->project_id,
                ],
            ]);
        }
        
        return response()->json($issue->load('column'));
    }

    public function deposit($id)
    {
        $issue = Issue::findOrFail($id);
        $issue->deposit = true;
        $issue->save();
        
        return response()->json($issue);
    }
    public function getStats($projectId)
    {
        try {
            
            $project = Project::findOrFail($projectId);
            
            
            $total = Issue::where('project_id', $projectId)->count();
            
            
            
            $openColumns = \App\Models\Column::where(function($query) {
                $query->where('name', 'NOT LIKE', '%done%')
                      ->where('name', 'NOT LIKE', '%closed%');
            })->pluck('id');
            
            $doneColumns = \App\Models\Column::where(function($query) {
                $query->where('name', 'LIKE', '%done%')
                      ->orWhere('name', 'LIKE', '%closed%');
            })->pluck('id');
            
            $open = Issue::where('project_id', $projectId)
                        ->whereIn('column_id', $openColumns)
                        ->count();
            
            $done = Issue::where('project_id', $projectId)
                        ->whereIn('column_id', $doneColumns)
                        ->count();
            
            return response()->json([
                'total' => $total,
                'open' => $open,
                'done' => $done,
            ]);
        } catch (\Exception $e) {
            
            \Illuminate\Support\Facades\Log::error('Issue stats error: ' . $e->getMessage());
            
            
            return response()->json([
                'error' => 'Failed to fetch issue statistics',
                'details' => $e->getMessage()
            ], 500);
        }
    }


public function getProjectIssues($projectId)
{
    $project = Project::findOrFail($projectId);
    
    
    $issues = Issue::with([
                'assignee', 
                'reporter', 
                'project', 
                'column'
            ])
            ->where('project_id', $projectId)
            ->latest() 
            ->get();
    
    
    $formattedIssues = $issues->map(function($issue) {
        
        if ($issue->column && !isset($issue->status)) {
            $issue->setAttribute('status', $issue->column->name);
        }
        
        
        if (empty($issue->key) && !empty($issue->project) && !empty($issue->project->key)) {
            $issue->setAttribute('key', $issue->project->key . '-' . $issue->id);
        } elseif (empty($issue->key)) {
            $issue->setAttribute('key', 'ISSUE-' . $issue->id);
        }
        
        return $issue;
    });
    
    return response()->json($formattedIssues);
}

public function createProjectIssue(Request $request, $projectId)
{
    \Illuminate\Support\Facades\Log::info('Create Issue Request:', $request->all());

    $priorityMap = [
        'low' => 1,
        'medium' => 2,
        'high' => 3
    ];

    $validator = \Illuminate\Support\Facades\Validator::make($request->all(), [
        'title' => 'required|string|max:255',
        'description' => 'nullable|string',
        'type' => 'required|in:task,bug,story,epic',
        'priority' => 'required|string|in:low,medium,high',
        'status' => 'required|string',
        'assignee_id' => 'nullable|exists:users,id',
        'due_date' => 'nullable|date',
    ]);

    if ($validator->fails()) {
        return response()->json([
            'message' => 'Validation failed',
            'errors' => $validator->errors()
        ], 422);
    }

    try {
        
        $project = \App\Models\Project::findOrFail($projectId);
        $user = $request->user();

        
        $board = \App\Models\Board::where('project_id', $project->id)->first();
        if (!$board) {
            
            $board = \App\Models\Board::create([
                'name' => 'Default Board',
                'project_id' => $project->id,
            ]);
            
            
            $defaultColumns = ['To Do', 'In Progress', 'Done'];
            foreach ($defaultColumns as $index => $name) {
                \App\Models\Column::create([
                    'name' => strtolower(str_replace(' ', '_', $name)),
                    'board_id' => $board->id,
                    'project_id' => $project->id,
                    'position' => $index,
                ]);
            }
        }

        
        $status = strtolower(str_replace(' ', '_', $request->status));

        
        $column = \App\Models\Column::firstOrCreate(
            ['name' => $status, 'project_id' => $projectId, 'board_id' => $board->id],
            ['position' => 0]
        );

        
        $validated = $validator->validated();
        $priorityValue = $priorityMap[strtolower($validated['priority'])];

        
        $issue = new \App\Models\Issue();
        $issue->title = $validated['title'];
        $issue->description = $validated['description'] ?? '';
        $issue->type = strtolower($validated['type']);
        $issue->priority = $priorityValue;
        $issue->status = $status;
        $issue->project_id = $projectId;
        $issue->column_id = $column->id;
        $issue->reporter_id = $user->id;
        $issue->assignee_id = $validated['assignee_id'] ?? null;
        $issue->due_date = $validated['due_date'] ?? null;
        $issue->deposit = false;
        
        
        if (!empty($project->key)) {
            $lastIssueId = \App\Models\Issue::where('project_id', $projectId)->max('id') ?? 0;
            $nextIssueNumber = $lastIssueId + 1;
            $issue->key = $project->key . '-' . $nextIssueNumber;
        }
        
        $issue->save();

        
        if ($issue->assignee_id) {
            \App\Models\Notification::create([
                'user_id' => $issue->assignee_id,
                'title' => 'New Issue Assigned',
                'message' => 'You have been assigned to issue: ' . $issue->title,
                'data' => [
                    'issue_id' => $issue->id,
                    'project_id' => $issue->project_id,
                ],
            ]);
        }

        
        $issue = $issue->fresh(['assignee', 'reporter', 'project', 'column']);

        \Illuminate\Support\Facades\Log::info('Issue created successfully:', [
            'id' => $issue->id,
            'key' => $issue->key,
            'title' => $issue->title,
            'column_id' => $issue->column_id,
            'column_name' => $issue->column ? $issue->column->name : null
        ]);

        return response()->json($issue, 201);

    } catch (\Exception $e) {
        \Illuminate\Support\Facades\Log::error("Issue creation failed: " . $e->getMessage());

        return response()->json([
            'error' => 'Failed to create issue',
            'details' => $e->getMessage()
        ], 500);
    }
}

public function changeStatus(Request $request, $id)
{
    $user = $request->user();
    $issue = Issue::with('column')->findOrFail($id);

    $validator = Validator::make($request->all(), [
        'status' => 'required|string|in:to_do,seen,in_progress,in_review,done',
        'comment' => 'nullable|string',
    ]);

    if ($validator->fails()) {
        return response()->json($validator->errors(), 422);
    }

    $status = $request->status;
    $comment = $request->comment;

    
    $validTransitions = [
        'to_do' => ['seen'],
        'seen' => ['in_progress'],
        'in_progress' => ['in_review', 'done'],
        'in_review' => ['in_progress', 'done'],
        'done' => [] 
    ];

    if (!in_array($status, $validTransitions[$issue->column->name] ?? [])) {
        return response()->json(['message' => 'Invalid status transition'], 400);
    }

    
    if ($status === 'done' && !$user->isAdmin() && !$user->isSuperAdmin()) {
        return response()->json(['message' => 'Only admins can mark as done'], 403);
    }

    if (($status === 'in_progress' || $status === 'in_review') && $issue->assignee_id !== $user->id) {
        return response()->json(['message' => 'Only assignee can perform this action'], 403);
    }

    
    $column = Column::firstOrCreate(
        ['name' => $status, 'project_id' => $issue->project_id, 'board_id' => $issue->column->board_id ?? 1],
        ['position' => array_search($status, ['to_do', 'seen', 'in_progress', 'in_review', 'done']) ?: 0]
    );

    
    $issue->column_id = $column->id;
    $issue->save();

    
    if ($comment) {
        $issue->comments()->create([
            'user_id' => $user->id,
            'content' => $comment,
        ]);
    }

    
    $this->createStatusNotification($issue, $status, $user);

    return response()->json($issue->fresh()->load('column'));
}
private function createStatusNotification($issue, $newStatus, $user)
{
    $messages = [
        'seen' => [
            'title' => 'Issue Viewed',
            'message' => 'Your issue "' . $issue->title . '" has been viewed by the assignee',
            'recipient' => $issue->reporter_id
        ],
        'in_progress' => [
            'title' => 'Work Started',
            'message' => 'Work has started on issue "' . $issue->title . '"',
            'recipient' => $issue->reporter_id
        ],
        'in_review' => [
            'title' => 'Ready for Review',
            'message' => 'Issue "' . $issue->title . '" is ready for your review',
            'recipient' => $issue->reporter_id
        ],
        'done' => [
            'title' => 'Issue Completed',
            'message' => 'Issue "' . $issue->title . '" has been marked as done',
            'recipient' => $issue->reporter_id
        ]
    ];

    if (isset($messages[$newStatus])) {
        Notification::create([
            'user_id' => $messages[$newStatus]['recipient'],
            'title' => $messages[$newStatus]['title'],
            'message' => $messages[$newStatus]['message'],
            'data' => [
                'issue_id' => $issue->id,
                'project_id' => $issue->project_id,
                'type' => 'issue_status_changed'
            ],
        ]);
    }
}


}