include ActionView::Helpers::NumberHelper

# The user that will be marked as the deleter of artifacts
# Note: set this to nil to have it marked as a system deletion
responsible_user = User.find_by(username: 'jondoe')

dry_run = true
verbose = true

# Look at global projects and find the 20 with the largest artifact repositories
ProjectStatistics.order(build_artifacts_size: :desc).limit(20).each do |prj_stat|

  puts "Checking #{prj_stat.project.full_path} => Total Artifacts: #{number_to_human_size(prj_stat.build_artifacts_size)}" if verbose

  project = Project.find_by_full_path(prj_stat.project.full_path)

  # We're explicitly concerned with artifacts that *never* expire here
  # Note 1: with_downloadable_artifacts is not the only option here
  # Note 1b: with_existing_job_artifacts(Ci::JobArtifact.trace) is common
  # Note 2: where can be replaced with all if you don't want to constrain it
  builds_with_artifacts =  project.builds.with_downloadable_artifacts.where(artifacts_expire_at: nil)

  # Keep track of the size of all artifacts in this project
  # (this is the expected space purged)
  artifact_storage_sz = 0;

  # We arbitrarily chose 6 weeks as a floor, so we're looking for anything
  # that finished more than 6 weeks ago
  builds_to_purge = builds_with_artifacts.where("finished_at < ?", 6.week.ago)

  builds_to_purge.find_each do |build|
  # We want to keep artifacts for tags
    if build.erasable? && build.tag == false
      # At least in our environment it's seemingly possible to
      # have downloadable artifacts in a job, that don't have
      # a size set, and nil can't be automatically cast to 0
      # Note: Keep track of the total size (so we know how
      # much we purge or can be purged)
      artifact_storage_sz += build.artifacts_size if !build.artifacts_size.nil?

      # Do the actual artifact erase
      build.erase(erased_by: responsible_user) if dry_run == false

      puts "#{prj_stat.project.full_path} build[#{build.id}] created[#{build.created_at}] ref[#{build.ref}] Artifact Size[#{number_to_human_size(build.artifacts_size)}]" if verbose
    end
  end

  puts "#{prj_stat.project.full_path} purged #{number_to_human_size(artifact_storage_sz)} artifacts" if verbose
end
