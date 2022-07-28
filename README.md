# Misc Scripts

Miscellaneous scripts, snippets, and such

# Scripts

## gitlab_artifact_purge.rb

Purges artifacts from gitlab using the rails console. Filters and projects can
be set appropriately (lots of examples commented out).

To use: `cat gitlab_artifact_purge.rb | ./bin/rails console > logs/purgable_DATE.csv`
