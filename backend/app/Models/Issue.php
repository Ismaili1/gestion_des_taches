<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Issue extends Model
{
    use HasFactory;

    protected $fillable = [
        'title',
        'description',
        'key',
        'type', // task, bug, story, epic
        'priority', // 1, 2, 3 (high, medium, low)
        'status',
        'reporter_id',
        'assignee_id',
        'due_date',
        'story_points',
        'project_id',
        'column_id',
        'deposit', // 0 or 1 to indicate if deposited
    ];

    protected $casts = [
        'due_date' => 'date',
    ];

    public function project()
    {
        return $this->belongsTo(Project::class);
    }

    public function column()
    {
        return $this->belongsTo(Column::class);
    }

    public function reporter()
    {
        return $this->belongsTo(User::class, 'reporter_id');
    }

    public function assignee()
    {
        return $this->belongsTo(User::class, 'assignee_id');
    }

    public function comments()
    {
        return $this->hasMany(Comment::class);
    }

    public function attachments()
    {
        return $this->hasMany(Attachment::class);
    }
    public function getStatusAttribute()
    {
        return $this->column->name ?? 'to_do';
    }
}