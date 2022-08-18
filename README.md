# Misc Scripts

Miscellaneous scripts, snippets, and such

# Scripts

## gitlab_artifact_purge.rb

Purges artifacts from gitlab using the rails console. Filters and projects can
be set appropriately (lots of examples commented out).

To use: `cat gitlab_artifact_purge.rb | ./bin/rails console > logs/purgable_DATE.csv`

## analyze_gitlab_artifacts.rb

Iterates over a list of gitlab projects, collects all of the builds with
artifacts that don't expire for that project, collapses the builds into a
pipeline, and summarizes the size of artifacts for that pipeline with some meta
data about the pipeline. Output is a CSV.

To use: `cat analyze_gitlab_artifacts.rb | ./bin/rails console > logs/project_pipelines_artifacts_<DATE>.csv`

## tailored_purge.rb

Takes a static "list" of pipelines and purges all artifacts for it (I created
the list with manual review of the output of analyze_gitlab_artifacts.rb). 

To use: `cat tailored_purge.rb | ./bin/rails console`
