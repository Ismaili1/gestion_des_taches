<?php
namespace App\Http\Controllers\API;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;

class UserController extends Controller
{
    public function index(Request $request)
    {
        $user = $request->user();
        
        if ($user->isSuperAdmin()) {
            $users = User::all();
        } elseif ($user->isAdmin()) {
            $users = User::where('direction', $user->direction)->get();
        } else {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        return response()->json($users);
    }

    public function store(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users',
            'password' => 'required|string|min:8',
            'role' => 'required|in:admin,user,Developer,Project Manager,Team Lead,QA,Designer',
            'direction' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        // Authorization check
        $currentUser = $request->user();
        if (!$currentUser->isSuperAdmin() && 
            ($currentUser->isAdmin() && $request->direction != $currentUser->direction)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'direction' => $request->direction,
        ]);

        return response()->json($user, 201);
    }

    public function show($id)
    {
        $user = User::findOrFail($id);
        
        // Authorization check
        $currentUser = request()->user();
        if (!$currentUser->isSuperAdmin() && 
            ($currentUser->isAdmin() && $user->direction != $currentUser->direction) && 
            $currentUser->id != $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        return response()->json($user);
    }

    public function update(Request $request, $id)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $id,
            'role' => 'required|in:admin,user',
            'direction' => 'required|string',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = User::findOrFail($id);
        
        // Authorization check
        $currentUser = $request->user();
        if (!$currentUser->isSuperAdmin() && 
            ($currentUser->isAdmin() && $user->direction != $currentUser->direction) && 
            $currentUser->id != $user->id) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }

        $user->name = $request->name;
        $user->email = $request->email;
        $user->role = $request->role;
        $user->direction = $request->direction;
        
        if ($request->password) {
            $user->password = Hash::make($request->password);
        }
        
        $user->save();
        
        return response()->json($user);
    }

    public function destroy(Request $request, $id)
    {
        $user = User::findOrFail($id);
        
        // Authorization check
        $currentUser = $request->user();
        if (!$currentUser->isSuperAdmin() && 
            ($currentUser->isAdmin() && $user->direction != $currentUser->direction)) {
            return response()->json(['message' => 'Unauthorized'], 403);
        }
        
        // Cannot delete yourself
        if ($currentUser->id == $user->id) {
            return response()->json(['message' => 'Cannot delete your own account'], 422);
        }
        
        $user->delete();
        
        return response()->json(null, 204);
    }

    public function profile(Request $request)
    {
        $user = $request->user();
        $user->load('assignedIssues', 'reportedIssues', 'projects');
        
        return response()->json($user);
    }
    public function search(Request $request)
{
    $query = $request->query('query', '');

    // Authenticated user
    $currentUser = $request->user();

    // Build base query depending on role
    $users = User::query();

    if ($currentUser->isAdmin()) {
        $users->where('direction', $currentUser->direction);
    } elseif (!$currentUser->isSuperAdmin()) {
        return response()->json(['message' => 'Unauthorized'], 403);
    }

    if ($query) {
        $users->where(function ($q) use ($query) {
            $q->where('name', 'like', "%$query%")
              ->orWhere('email', 'like', "%$query%");
        });
    }

    return response()->json($users->get());
}


    public function updateProfile(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:users,email,' . $request->user()->id,
            'current_password' => 'nullable|string',
            'new_password' => 'nullable|string|min:8|required_with:current_password',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $user = $request->user();
        
        // Check current password if updating password
        if ($request->current_password) {
            if (!Hash::check($request->current_password, $user->password)) {
                return response()->json(['message' => 'Current password is incorrect'], 422);
            }
            
            $user->password = Hash::make($request->new_password);
        }
        
        $user->name = $request->name;
        $user->email = $request->email;
        $user->save();
        
        return response()->json($user);
    }
}