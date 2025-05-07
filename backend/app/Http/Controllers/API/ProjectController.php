<?php

namespace App\Http\Controllers\API;
use App\Http\Requests\AddProjectMemberRequest;
use Illuminate\Support\Facades\DB;
use App\Notifications\ProjectMembershipNotification;
use App\Models\Column;
use App\Models\Issue;
use App\Models\Board;
use App\Http\Controllers\Controller;
use App\Models\Project;
use App\Models\Notification;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;

class ProjectController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();

        
        if ($user->isSuperAdmin()) {
            $projects = Project::with('lead', 'members')->get();
        } elseif ($user->isAdmin()) {
            // Get projects where user is a lead (created by them)
            $ledProjects = Project::where('lead_id', $user->id)
                ->with('lead', 'members')
                ->get();
                
            // Get projects based on direction
            $directionProjects = Project::where('direction', $user->direction)
                ->with('lead', 'members')
                ->get();
                
            // Get projects where user is a member
            $memberProjects = $user->projects()->with('lead', 'members')->get();
            
            // Merge all collections and remove duplicates
            $projects = $ledProjects->concat($directionProjects)->concat($memberProjects)->unique('id');
        } else {
            $projects = $user->projects()->with('lead', 'members')->get();
        }
        
        // Debug information - output to logs
        Log::info('User ID: ' . $user->id);
        Log::info('User Role: ' . $user->role);
        Log::info('User Direction: ' . $user->direction);
        Log::info('Projects count: ' . $projects->count());
        foreach ($projects as $p) {
            Log::info("Project ID: {$p->id}, Name: {$p->name}, Lead: {$p->lead_id}, Direction: {$p->direction}");
        }
        
        // Cache::put($cacheKey, $projects, $cacheDuration);
        return response()->json($projects);
    }

    public function store(Request $request)
    {
        Log::debug('Project Creation Request:', $request->all());

        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'key' => 'required|string|max:10|unique:projects',
            'description' => 'nullable|string',
            'lead_id' => 'required|exists:users,id',
            'direction' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $user = $request->user();
        if (!$user->isAdmin() && !$user->isSuperAdmin()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        try {
            DB::beginTransaction();

            $project = Project::create($request->all());
            Log::debug('Project created with ID: ' . $project->id);

            $project->members()->attach($request->lead_id, ['role' => 'admin']);
            if ($user->id != $request->lead_id) {
                $project->members()->attach($user->id, ['role' => 'admin']);
            }

            $board = Board::create([
                'name' => 'Default Board',
                'project_id' => $project->id,
            ]);

            $defaultColumns = ['To Do', 'In Progress', 'Done'];
            foreach ($defaultColumns as $index => $name) {
                Column::create([
                    'name' => $name,
                    'board_id' => $board->id,
                    'project_id' => $project->id,
                    'position' => $index,
                ]);
            }

            Cache::flush();

            // Reload the project with relations
            $project = Project::with(['lead', 'members'])->find($project->id);

            if (!$project || !$project->lead) {
                throw new \Exception("Lead not loaded properly after creation");
            }

            DB::commit();
            return response()->json($project, 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Project creation failed: ' . $e->getMessage());
            return response()->json([
                'message' => 'Failed to create project: ' . $e->getMessage()
            ], 500);
        }
    }

    public function show($id)
    {
        $project = Project::with('lead', 'members', 'boards.columns.issues')->findOrFail($id);
        
        return response()->json($project);
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'key' => 'required|string|max:10|unique:projects,key,' . $id,
            'description' => 'nullable|string',
            'lead_id' => 'required|exists:users,id',
            'direction' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $project = Project::findOrFail($id);
        $oldLeadId = $project->lead_id;
        
        // Get all member IDs before updating
        $memberIds = $project->members()->pluck('id')->toArray();
        
        $project->update($request->all());
        
        // If lead has changed, add the new lead ID to the list
        if ($oldLeadId != $request->lead_id && !in_array($request->lead_id, $memberIds)) {
            $memberIds[] = $request->lead_id;
        }
        
        // Clear any existing cache
        Cache::flush();
        
        return response()->json($project);
    }

    public function destroy(Request $request, $id)
    {
        try {
            $project = Project::with(['issues', 'boards', 'members'])->findOrFail($id);
            $user = $request->user();

            // Enhanced authorization check
            if (!$user->isAdmin() && !$user->isSuperAdmin() && $project->lead_id != $user->id) {
                return response()->json([
                    'message' => 'Unauthorized - Only admins or project leads can delete projects'
                ], 403);
            }

            DB::beginTransaction();

            // Clean up relationships
            $project->issues()->delete();
            $project->boards()->delete();
            $project->members()->detach();

            // Delete the project
            $project->delete();

            DB::commit();
            
            Cache::flush();
            
            return response()->json(null, 204);
            
        } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
            return response()->json([
                'message' => 'Project not found'
            ], 404);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error("Project deletion failed: {$e->getMessage()}");
            return response()->json([
                'message' => 'Project deletion failed',
                'error' => config('app.debug') ? $e->getMessage() : null
            ], 500);
        }
    }

    public function addMember(Request $request, $projectId)
    {
        $project = Project::findOrFail($projectId);

        Log::info('Incoming addMember request', $request->all());
        Log::info('Authenticated user:', [
            'id' => $request->user()->id,
            'role' => $request->user()->role,
        ]);

        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
            'role' => 'required|string|in:Developer,QA,Designer,Observer',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        if ($project->members()->where('user_id', $request->user_id)->exists()) {
            Log::info('User already exists in project', [
                'user_id' => $request->user_id,
                'project_id' => $project->id,
            ]);

            return response()->json([
                'message' => 'User is already a member of this project',
            ], 422);
        }

        $user = $request->user();
        if (!$user->isAdmin() && !$user->isSuperAdmin() && $project->lead_id != $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        try {
            DB::beginTransaction();

            // Attach the member
            $project->members()->attach($request->user_id, [
                'role' => $request->role,
            ]);
            Log::info('Member attached successfully', [
                'user_id' => $request->user_id,
                'project_id' => $project->id,
                'role' => $request->role,
            ]);

            // Create notification
            $notification = Notification::create([
                'user_id' => $request->user_id,
                'title' => 'Added to Project',
                'message' => "You were added to project {$project->name} by {$user->name}",
                'data' => [
                    'type' => 'project_membership',
                    'project_id' => $project->id,
                    'project_name' => $project->name,
                    'added_by' => $user->id,
                    'added_by_name' => $user->name,
                    'role' => $request->role,
                ],
                'read_at' => null,
            ]);
            Log::info('Notification created successfully', ['id' => $notification->id]);

            Cache::forget("project_{$project->id}_members");

            DB::commit();

            return response()->json([
                'message' => 'Member added successfully',
                'notification' => $notification,
                'project' => $project->load('members'),
            ], 201);
        } catch (\Exception $e) {
            DB::rollBack();
            Log::error('Exception while adding member', [
                'error' => $e->getMessage(),
            ]);
            return response()->json(['message' => 'Failed to add member'], 500);
        }
    }

    /**
     * Remove a member from a project
     * 
     * @param Request $request
     * @param int $projectId
     * @return \Illuminate\Http\JsonResponse
     */
    public function removeMember(Request $request, $projectId)
{
    try {
        Log::info('Removing project member', [
            'project_id' => $projectId,
            'request_data' => $request->all()
        ]);
        
        $validator = Validator::make($request->all(), [
            'user_id' => 'required|exists:users,id',
        ]);

        if ($validator->fails()) {
            return response()->json([
                'message' => 'Validation failed',
                'errors' => $validator->errors()
            ], 422);
        }

        $project = Project::findOrFail($projectId);
        $user = $request->user();
        $userIdToRemove = $request->user_id;

        // Authorization check
        if (!$user->isAdmin() && !$user->isSuperAdmin() && $project->lead_id != $user->id) {
            return response()->json(['message' => 'Unauthorized to remove members'], 403);
        }

        // Cannot remove project lead
        if ($project->lead_id == $userIdToRemove) {
            return response()->json([
                'message' => 'Cannot remove project lead from members'
            ], 422);
        }

        // Check if user is a member
        if (!$project->members()->where('user_id', $userIdToRemove)->exists()) {
            return response()->json([
                'message' => 'User is not a member of this project'
            ], 404);
        }

        DB::beginTransaction();

        // ✅ Delete issues assigned to this user in this project
        $deletedCount = Issue::where('project_id', $project->id)
            ->where('assignee_id', $userIdToRemove)
            ->delete();

        Log::info("Deleted {$deletedCount} issues assigned to user {$userIdToRemove} in project {$project->id}");

        // Detach the member
        $project->members()->detach($userIdToRemove);

        // Create notification
        Notification::create([
            'user_id' => $userIdToRemove,
            'title' => 'Removed from Project',
            'message' => "You were removed from project {$project->name} by {$user->name}",
            'data' => [
                'type' => 'project_membership_removed',
                'project_id' => $project->id,
                'project_name' => $project->name,
                'removed_by' => $user->id,
                'removed_by_name' => $user->name,
            ],
            'read_at' => null,
        ]);

        Cache::forget("project_{$project->id}_members");

        DB::commit();

        return response()->json([
            'message' => 'Member removed successfully',
            'project' => $project->load('members'),
        ], 200);
        
    } catch (\Illuminate\Database\Eloquent\ModelNotFoundException $e) {
        DB::rollBack();
        Log::error('Project not found when removing member', [
            'project_id' => $projectId,
            'error' => $e->getMessage()
        ]);
        return response()->json(['message' => 'Project not found'], 404);
    } catch (\Exception $e) {
        DB::rollBack();
        Log::error('Error removing project member', [
            'project_id' => $projectId,
            'error' => $e->getMessage(),
            'trace' => $e->getTraceAsString()
        ]);
        return response()->json(['message' => 'Failed to remove member: ' . $e->getMessage()], 500);
    }
}


}