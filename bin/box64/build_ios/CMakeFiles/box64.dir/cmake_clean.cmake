file(REMOVE_RECURSE
  "box64"
  "box64.pdb"
)

# Per-language clean rules from dependency scanning.
foreach(lang C)
  include(CMakeFiles/box64.dir/cmake_clean_${lang}.cmake OPTIONAL)
endforeach()
