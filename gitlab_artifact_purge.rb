include ActionView::Helpers::NumberHelper

# The user that will be marked as the deleter of artifacts
# Note: set this to nil to have it marked as a system deletion
# Note2: If this is not set, we'll force it to be the build user
responsible_user = User.find_by(username: 'jdoe')

dry_run = true
verbose = true
force_update_statistics = true

# CSV Header
puts "Project,Build ID,Pipeline ID,User,Created,Ref,Ref Exists,Latest Pipeline,Tag,Erasable,Artifact Size" if verbose

# List(array) of projects we want to purge artifacts from
gitlab_projects = [ "namespace1/project1", "namespace1/project2", "namespace2/project1", "namespace2/project2" ]

gitlab_projects.find_all do |cur_proj|
  project = Project.find_by_full_path(cur_proj)

  # We're explicitly concerned with artifacts that *never* expire here
  # Note 1: with_downloadable_artifacts is not the only option here
  # Note 1b: with_existing_job_artifacts(Ci::JobArtifact.trace) is common
  # Note 2: where can be replaced with all if you don't want to constrain it
  builds_with_artifacts =  project.builds.with_downloadable_artifacts.where(artifacts_expire_at: nil)
  #builds_with_artifacts =  project.builds.with_downloadable_artifacts

  # Keep track of the size of all artifacts in this project
  # (this is the expected space purged)
  artifact_storage_sz = 0;

  # We arbitrarily chose 6 weeks as a floor, so we're looking for anything
  # that finished more than 6 weeks ago
  builds_to_purge = builds_with_artifacts.where("finished_at < ?", 6.week.ago)

  builds_to_purge.find_each do |build|
    #We want to keep artifacts for tags
    #if build.erasable? && build.tag == false && !build.ref.eql?("master")
    #if build.erasable? && !build.ref.eql?("master") && (build.ref =~ /rc\d+/) && !(build.ref =~ /(?:FilterN|FilterN|FilterN|FilterN)/)
    if !(build.ref =~ /(?:FilterN|FilterN|FilterN|FilterN)/) && !build.pipeline.ref_exists?

      # At least in our environment it's seemingly possible to
      # have downloadable artifacts in a job, that don't have
      # a size set, and nil can't be automatically cast to 0
      # Note: Keep track of the total size (so we know how
      # much we purge or can be purged)
      artifact_storage_sz += build.artifacts_size if !build.artifacts_size.nil?

      # We can gave deleted users (i.e. former employees) who created non
      # expiring pipelines
      build_user = User.ghost if !(build_user = User.find_by(id: build.user_id))

      build_username = "UNKNOWN"

      build_username = build_user.username if (build_user && build_user.username)

      # Mostly for purging former employee pipelines, make them "responsible"
      # for their own deletions
      responsible_user = build_user if !responsible_user

      # An additional check / option / filter to only remove artifacts from
      # blocked users (mostly former employees that we blocked instead of
      # deleting to keep commit and pipeline histories
      #if build_user && build_user.blocked?
      # Note: we need a corresponding end if we use this conditional

      # Another option for manual review (check the created_at date compared to
      # now, the delta is in #days
      #build_age = DateTime.now.mjd - DateTime.parse(build.created_at.to_s()).mjd

      puts "#{cur_proj},#{build.id},#{build.pipeline.id},#{build_username},#{build.created_at},#{build.ref},#{build.pipeline.ref_exists?},#{build.pipeline.latest?},#{build.tag},#{build.erasable?},#{number_to_human_size(build.artifacts_size)}" if verbose

      # Do the actual artifact erase
      build.erase(erased_by: responsible_user) if dry_run == false
    end
  end

  cur_proj.statistics.refresh! if force_update_statistics

  # Now quite a CSV here but more useful for debugging
  puts ">> #{cur_proj} artifact size (erasable): #{number_to_human_size(artifact_storage_sz)}" if verbose
end
