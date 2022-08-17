include ActionView::Helpers::NumberHelper

# CSV header
puts "Project,Pipeline ID,User,Created At,Build Ref,Latest Pipeline,Tag,Size"

# List(array) of projects we want investigate artifacts for
gitlab_projects = [ "namespace1/project1", "namespace1/project2", "namespace2/project1", "namespace2/project2" ]

# This will end up as a multi-dimensional hash
# pipelines[project]=>{pipeline_id}=>array(build objects)
pipelines = Hash.new

# Collect all of the artifacts that don't expire and set up our multidimensional
# hash
gitlab_projects.find_all do |cur_proj|
  project = Project.find_by_full_path(cur_proj)

  pipelines[cur_proj] = Hash.new

  builds_with_artifacts =  project.builds.with_downloadable_artifacts.where(artifacts_expire_at: nil)

  # Push all of the builds into the pipeline array for the project
  builds_with_artifacts.find_each do |build|
    if( !pipelines[cur_proj].key?(build.pipeline.id) )
      pipelines[cur_proj][build.pipeline.id] = Array.new
    end

    pipelines[cur_proj][build.pipeline.id].push(build)
  end

end

# Calculate pipeline size and set base data
pipelines.each do |proj, proj_pipelines|
  proj_pipelines.each do |pipeline_id, pipeline_builds|

    pipeline_artifact_size = 0;

    user = nil
    created = nil
    ref = nil
    latest = nil
    tag = nil

    pipeline_builds.each do |build|
      # Set our "static" data for pipeline using the first build
      if( !user)
        build_user = User.ghost if !(build_user = User.find_by(id: build.user_id))

        user = build_user.username if (build_user && build_user.username)
      end

      created = build.created_at if !created
      ref = build.ref if !ref
      latest = build.pipeline.latest? if !latest
      tag = build.tag if !tag

      pipeline_artifact_size += build.artifacts_size if !build.artifacts_size.nil?
    end

    # Create our CSV
    puts "#{proj},#{pipeline_id},#{user},#{created},#{ref},#{latest},#{number_to_human_size(pipeline_artifact_size)}"
  end
end
