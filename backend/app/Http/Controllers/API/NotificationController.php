<?php


namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\Notification;
use Illuminate\Http\Request;

class NotificationController extends Controller
{
    public function index(Request $request)
    {
        $notifications = Notification::where('user_id', $request->user()->id)
            ->orderBy('created_at', 'desc')
            ->get();
        
        return response()->json($notifications);
    }

    public function markAsRead($id)
    {
        $notification = Notification::findOrFail($id);
        
        // Check that the user can only mark their own notifications as read
        if ($notification->user_id != auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        $notification->read_at = now();
        $notification->save();
        
        return response()->json($notification);
    }

    public function markAllAsRead(Request $request)
    {
        Notification::where('user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);
        
        return response()->json(['message' => 'All notifications marked as read']);
    }
    
    public function destroy($id)
    {
        $notification = Notification::findOrFail($id);
        
        // Ensure user can only delete their own notifications
        if ($notification->user_id != auth()->id()) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        $notification->delete();
        
        return response()->json(['message' => 'Notification deleted successfully']);
    }
}