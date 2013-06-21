class ExercismApp < Sinatra::Base

  helpers do
    def nitpick(id)
      submission = Submission.find(id)

      unless current_user.may_nitpick?(submission.exercise)
        halt 403, "You do not have permission to nitpick that exercise."
      end

      Nitpick.new(id, current_user, params[:comment]).save
    end

    def approve(id)
      unless current_user.admin?
        halt 403, "You do not have permission to approve that exercise."
      end
      Approval.new(id, current_user, params[:comment]).save
    end
  end

  get '/user/submissions/:id' do |id|
    submission = Submission.find(id)
    unless current_user == submission.user
      flash[:error] = 'That is not your submission.'
    end
    erb :submission, locals: {submission: Submission.find(id)}
  end

  get '/submissions/:id' do |id|
    submission = Submission.find(id)
    unless current_user.may_nitpick?(submission.exercise)
      flash[:error] = "You do not have permission to nitpick that exercise."
      redirect '/'
    end
    erb :nitpick, locals: {submission: submission}
  end

  # TODO: Write javascript to submit form here
  post '/submissions/:id/nitpick' do |id|
    nitpick(id)
    redirect '/'
  end

  # TODO: Write javascript to submit form here
  post '/submissions/:id/approve' do |id|
    approve(id)
    redirect '/'
  end

  # I don't like this, but I don't see how to make
  # the front-end to be able to use the same textarea for two purposes
  # without it. It seems like this is a necessary
  # fallback even if we implement the javascript stuff.
  post '/submissions/:id/respond' do |id|
    if params[:approve]
      approve(id)
    else
      nitpick(id)
    end
    redirect '/'
  end

  post '/submissions/:id/nits/:nit_id/argue' do |id, nit_id|
    if current_user.guest?
      flash[:error] = 'You are not authorized to argue about this.'
      redirect '/'
    end

    data = {
      submission_id: id,
      nit_id: nit_id,
      user: current_user,
      comment: params[:comment]
    }
    argument = Argument.new(data).save

    if argument.submission.user == current_user
      redirect "/user/submissions/#{id}"
    else
      redirect "/submissions/#{id}"
    end
  end

end