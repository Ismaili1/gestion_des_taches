<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'password',
        'role', // admin, user
        'direction' // general, other departments
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected $casts = [
        'email_verified_at' => 'datetime',
        'password' => 'hashed',
    ];

    public function projects()
    {
        return $this->belongsToMany(Project::class, 'project_members')
            ->withPivot('role')
            ->withTimestamps();
    }
   
    
    public function assignedIssues()
    {
        return $this->hasMany(Issue::class, 'assignee_id');
    }

    public function reportedIssues()
    {
        return $this->hasMany(Issue::class, 'reporter_id');
    }

    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    public function notifications()
    {
        return $this->hasMany(Notification::class);
    }

    public function isSuperAdmin()
    {
        return $this->role === 'admin' && $this->direction === 'general';
    }

    public function isAdmin()
    {
        return $this->role === 'admin' && $this->direction !== 'general';
    }

    public function isUser()
    {
        return $this->role === 'user';
    }

    
}