<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class AddProjectMemberRequest extends FormRequest
{
    public function authorize()
    {
        // Add your own policy checks if needed
        return true;
    }

    public function rules()
    {
        return [
            'user_id' => 'required|exists:users,id',
            'role'    => 'required|string|in:Developer,QA,Designer,Observer',
        ];
    }
}
