<?php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Board;
use App\Models\Column;
use App\Models\Project;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class BoardController extends Controller
{
    public function index($projectId)
    {
        $boards = Board::where('project_id', $projectId)
            ->with('columns.issues')
            ->get();
        
        return response()->json($boards);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'project_id' => 'required|exists:projects,id',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $board = Board::create($request->all());
        
        // Create default columns
        $defaultColumns = ['To Do', 'In Progress', 'Done'];
        foreach ($defaultColumns as $index => $name) {
            Column::create([
                'name' => $name,
                'board_id' => $board->id,
                'position' => $index,
            ]);
        }

        return response()->json($board->load('columns'), 201);
    }

    public function show($id)
    {
        $board = Board::with('columns.issues.assignee', 'columns.issues.reporter')
            ->findOrFail($id);
        
        return response()->json($board);
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $board = Board::findOrFail($id);
        $board->update($request->all());
        
        return response()->json($board);
    }

    public function destroy($id)
    {
        $board = Board::findOrFail($id);
        $board->delete();
        
        return response()->json(null, 204);
    }
    // Add this to BoardController.php
public function createForProject($projectId)
{
    // Check if project exists
    $project = Project::findOrFail($projectId);
    
    // Check if project already has a board
    $existingBoard = Board::where('project_id', $projectId)->first();
    if ($existingBoard) {
        return response()->json([
            'message' => 'Project already has a board',
            'board' => $existingBoard
        ], 422);
    }
    
    // Create a new board
    $board = Board::create([
        'name' => 'Default Board',
        'project_id' => $projectId,
    ]);
    
    // Create default columns
    $defaultColumns = ['To Do', 'In Progress', 'Done'];
    foreach ($defaultColumns as $index => $name) {
        Column::create([
            'name' => strtolower(str_replace(' ', '_', $name)),
            'board_id' => $board->id,
            'project_id' => $projectId,
            'position' => $index,
        ]);
    }
    
    return response()->json($board->load('columns'), 201);
}
}