# Define a static structure to use for our purge (this was ultimately created as
# a result of the analyze script
#
# We create a hash, where the keys are namespace/project, and each key contains
# an array of pipelines to destroy artifacts for
purgeable_pipelines = { "namespace/projA":
                        [37762, 37707, 38005, 38118, 38845, 39110, 40683, 45329, 45331, 45545, 45547, 45558, 45367, 45639, 4643, 45658, 45671, 45684, 45688, 45692, 45694, 45822, 45824, 45826, 45828, 45830, 45832, 45837, 45854, 45947, 45980, 45988, 46016, 46018, 46020, 46022, 46024, 46026, 46031, 46033, 46036, 46040, 46041, 46107, 46202, 46259, 46301, 46567, 46567, 44798, 44797, 45607, 45611, 45614, 45618, 45622, 45633, 45646, 45648, 45651, 45653, 45655, 45703, 45705, 45709, 45723, 45730, 45736, 45742, 45746, 45765, 45768, 45772, 45834, 45841, 45843, 45845, 45859, 45861, 45863, 45865, 45869, 45873, 45875, 45880, 45884, 45956, 45958, 45968, 45972, 46001, 46009, 46046, 46048, 46050, 46052, 46054, 46060, 46062, 46074, 46076, 46098, 46100, 46102, 46105, 46113, 46117, 46118, 46123, 46131, 46135, 46141, 46149, 46163, 46165, 46167, 46169, 46171, 46173, 46186, 46189, 46191, 46193, 46208, 46210, 46227, 46249, 46251, 46253, 46261, 46271, 46297, 46332, 46344, 46348, 46350, 46356, 46370, 46395, 46398, 46405, 46414, 46425, 46427, 46433, 46435, 46437, 46439, 46446, 46448, 46508, 46512, 46590, 46603, 46620, 46622, 46628, 46636, 46657, 46659, 46663, 46665, 46667, 46669, 46699, 46733, 46735, 46765, 46769, 46771, 46786, 46788, 46792, 46794, 46796, 46804, 46816, 46820, 46826, 46829],
                        "namespace/projB":
                        [37840, 37867, 38046, 38128, 38132, 38476, 39132, 40068, 40391, 40698, 40710, 40750, 41493, 41496, 43073, 43270],
                        "namespace/projC":
                        [18341, 18345, 18352, 18722, 18742, 18745, 18750, 18866, 18895, 18901, 21235]
}

# Loop through hash using each key/value pair
purgeable_pipelines.each do |cur_proj_str, proj_pipelines|
  # We need to resolve the namespace/project string to a Project obj
  cur_proj = Project.find_by_full_path(cur_proj_str)

  # Loop through our static pipeline ids for the project
  proj_pipelines.find_all do |pipeline_id|
    # Find all of the builds for the given pipeline
    purgable_builds = cur_proj.builds.where(pipeline: pipeline_id)

    # Walk the array of builds and erase themn
    purgable_builds.find_all do |cur_build|
      cur_build.artifacts_expire_at = Time.current
      cur_build.erase
    end
  end
end
