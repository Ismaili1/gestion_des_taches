<?php

namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Attachment;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Validator;

class AttachmentController extends Controller
{
    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'file' => 'required|file|max:10240', // 10MB max
            'issue_id' => 'required|exists:issues,id',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $file = $request->file('file');
        $path = $file->store('attachments');
        
        $attachment = Attachment::create([
            'file_name' => $file->getClientOriginalName(),
            'file_path' => $path,
            'issue_id' => $request->issue_id,
            'user_id' => $request->user()->id,
        ]);
        
        return response()->json($attachment, 201);
    }

    public function destroy(Request $request, $id)
    {
        $attachment = Attachment::findOrFail($id);
        
        // Check if user uploaded the attachment
        if ($attachment->user_id !== $request->user()->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        // Delete file from storage
        Storage::delete($attachment->file_path);
        
        $attachment->delete();
        
        return response()->json(null, 204);
    }

    public function download($id)
    {
        $attachment = Attachment::findOrFail($id);
        
        return Storage::download($attachment->file_path, $attachment->file_name);
    }
}