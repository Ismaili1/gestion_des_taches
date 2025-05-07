<?php
namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;

class Column extends Model
{
    use HasFactory;

    protected $fillable = [
        'name',
        'board_id',
        'position',
        'project_id', 
    ];
    public function project()
{
    return $this->belongsTo(Project::class);
}


    public function board()
    {
        return $this->belongsTo(Board::class);
    }

    public function issues()
    {
        return $this->hasMany(Issue::class);
    }
}