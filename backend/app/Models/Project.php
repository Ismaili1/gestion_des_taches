<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Project extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'key',
        'description',
        'lead_id',
        'direction'
    ];

    // public function lead()
    // {
    //     return $this->belongsTo(User::class, 'lead_id');
    // }
    public function lead()
{
    return $this->belongsTo(User::class, 'lead_id')->withDefault([
        'id' => -1,
        'name' => 'Unknown Lead',
        'email' => '',
        'role' => 'guest',
        'direction' => '',
        'created_at' => now(),
    ]);
}

    public function members()
    {
        return $this->belongsToMany(User::class, 'project_members')
            ->withPivot('role')
            ->withTimestamps();
    }

    public function issues()
    {
        return $this->hasMany(Issue::class);
    }

    public function boards()
    {
        return $this->hasMany(Board::class);
    }
    public function board()
{
    return $this->belongsTo(Board::class);
}

}