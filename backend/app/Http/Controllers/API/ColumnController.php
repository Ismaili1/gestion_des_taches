<?php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Column;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;

class ColumnController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'board_id' => 'required|exists:boards,id',
            'position' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $column = Column::create($request->all());
        
        return response()->json($column, 201);
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'position' => 'required|integer',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $column = Column::findOrFail($id);
        $column->update($request->all());
        
        return response()->json($column);
    }

    public function destroy($id)
    {
        $column = Column::findOrFail($id);
        
        // Check if column has issues
        if ($column->issues()->count() > 0) {
            return response()->json(['message' => 'Cannot delete column with issues'], 422);
        }
        
        $column->delete();
        
        return response()->json(null, 204);
    }
}