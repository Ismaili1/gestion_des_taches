<?php
namespace App\Http\Controllers\API;

use Illuminate\Support\Facades\Log;
use App\Http\Controllers\Controller;
use App\Models\Comment;
use App\Models\Issue;
use App\Models\Notification;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class CommentController extends Controller
{

    public function index($projectId, $issueId)
{
    // Add debugging
    Log::info("Fetching comments for project ID: $projectId and issue ID: $issueId");
    
    // Check if the issue exists
    $issue = Issue::where('id', $issueId)
        ->where('project_id', $projectId)
        ->first();
    
    if (!$issue) {
        Log::warning("Issue not found with ID: $issueId in project: $projectId");
        return response()->json(['message' => 'Issue not found'], 404);
    }
    
    // Get the comments
    $comments = Comment::where('issue_id', $issueId)
        ->with('user')
        ->orderBy('created_at', 'desc')
        ->get();
    
    Log::info("Found " . $comments->count() . " comments for issue ID: $issueId");
    
    return response()->json($comments);
}

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'content' => 'required|string',
            'issue_id' => 'required|exists:issues,id',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $comment = Comment::create([
            'content' => $request->content,
            'issue_id' => $request->issue_id,
            'user_id' => $request->user()->id,
        ]);
        
        // Create notification for issue assignee
        $issue = Issue::findOrFail($request->issue_id);
        if ($issue->assignee_id && $issue->assignee_id != $request->user()->id) {
            Notification::create([
                'user_id' => $issue->assignee_id,
                'title' => 'New Comment on Issue',
                'message' => 'New comment on issue: ' . $issue->title,
                'data' => [
                    'issue_id' => $issue->id,
                    'project_id' => $issue->project_id,
                ],
            ]);
        }
        
        return response()->json($comment->load('user'), 201);
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'content' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $comment = Comment::findOrFail($id);
        
        // Check if user owns the comment
        if ($comment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        $comment->content = $request->content;
        $comment->save();
        
        return response()->json($comment->load('user'));
    }

    public function destroy(Request $request, $id)
    {
        $comment = Comment::findOrFail($id);
        
        // Check if user owns the comment
        if ($comment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        $comment->delete();
        
        return response()->json(null, 204);
    }
}