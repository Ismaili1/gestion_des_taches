<?php
use App\Http\Controllers\API\AttachmentController;
use App\Http\Controllers\API\AuthController;
use App\Http\Controllers\API\BoardController;
use App\Http\Controllers\API\ColumnController;
use App\Http\Controllers\API\CommentController;
use App\Http\Controllers\API\IssueController;
use App\Http\Controllers\API\NotificationController;
use App\Http\Controllers\API\ProjectController;
use App\Http\Controllers\API\UserController;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;

// Public routes
Route::post('/register', [AuthController::class, 'register']);
Route::post('/login', [AuthController::class, 'login']);

// Protected routes
Route::middleware('auth:sanctum')->group(function () {
    // Auth
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/user', [AuthController::class, 'user']);
    
    // Projects
    Route::post('projects/{projectId}/create-board', [BoardController::class, 'createForProject']);
    Route::apiResource('projects', ProjectController::class);
    Route::post('projects/{projectId}/members', [ProjectController::class, 'addMember']);
    // Route::delete('/projects/{id}/members', [ProjectController::class, 'removeMember']);   
    Route::delete('projects/{projectId}/members', [ProjectController::class, 'removeMember']);

    
    // Boards
    Route::get('/projects/{projectId}/boards', [BoardController::class, 'index']);
    Route::apiResource('boards', BoardController::class)->except(['index']);
    
    // Columns
    Route::apiResource('columns', ColumnController::class)->except(['index', 'show']);
    
    // Issues
    Route::patch('/issues/{id}/status', [IssueController::class, 'changeStatus']);
    Route::post('/projects/{projectId}/issues', [IssueController::class, 'createProjectIssue']);
    Route::get('/projects/{projectId}/issues', [IssueController::class, 'getProjectIssues']);
    Route::get('/projects/{projectId}/issues/stats', [IssueController::class, 'getStats']);
    Route::apiResource('issues', IssueController::class);
    Route::patch('/issues/{id}/column', [IssueController::class, 'updateColumn']);
    Route::patch('/issues/{id}/deposit', [IssueController::class, 'deposit']);
    
    // Comments
    Route::get('/projects/{projectId}/issues/{issueId}/comments', [CommentController::class, 'index']);
    Route::post('/projects/{projectId}/issues/{issueId}/comments', [CommentController::class, 'store']);
    Route::put('/comments/{id}', [CommentController::class, 'update']);
    Route::delete('/comments/{id}', [CommentController::class, 'destroy']);
    
    // Attachments
    Route::post('/attachments', [AttachmentController::class, 'store']);
    Route::delete('/attachments/{id}', [AttachmentController::class, 'destroy']);
    Route::get('/attachments/{id}/download', [AttachmentController::class, 'download']);
    
    // Notifications
    Route::get('/notifications', [NotificationController::class, 'index']);
    Route::patch('/notifications/{id}/read', [NotificationController::class, 'markAsRead']);
    Route::patch('/notifications/read-all', [NotificationController::class, 'markAllAsRead']);
    Route::delete('/notifications/{id}', [NotificationController::class, 'destroy']);
    
    // Users
    Route::get('/users/search', [UserController::class, 'search']);
    Route::apiResource('users', UserController::class);
    Route::get('/profile', [UserController::class, 'profile']);
    Route::put('/profile', [UserController::class, 'updateProfile']);
});
Route::options('/{any}', function (Request $request) {
    return response('', 204)
        ->header('Access-Control-Allow-Origin', '*')
        ->header('Access-Control-Allow-Methods', 'GET, POST, PUT, DELETE, OPTIONS')
        ->header('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept, Authorization');
})->where('any', '.*');

