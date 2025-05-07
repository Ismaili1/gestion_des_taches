<?php

namespace App\Notifications;

use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Notification;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Notifications\Messages\MailMessage;

class ProjectMembershipNotification extends Notification
{
    use Queueable;

    private $project;
    private $addedBy;
    private $userId;

    public function __construct($project, $addedBy, $userId)
    {
        $this->project = $project;
        $this->addedBy = $addedBy;
        $this->userId = $userId;
    }

    public function via($notifiable)
    {
        return ['database'];
    }

public function toArray($notifiable)
{
    return [
        'title' => 'Added to Project',
        'message' => "You were added to project \"" . $this->project->name . "\" by " . $this->addedBy->name,
        'project_id' => $this->project->id,
        'project_name' => $this->project->name,
        'added_by' => $this->addedBy->id,
        'added_by_name' => $this->addedBy->name,
        'role' => 'member',
    ];
}
}