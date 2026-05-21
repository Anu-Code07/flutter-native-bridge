cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "nativeflow_bridge_linux")
project(${PROJECT_NAME} LANGUAGES CXX)

set(PLUGIN_NAME "nativeflow_bridge_linux_plugin")

add_library(${PLUGIN_NAME} SHARED
  "nativeflow_bridge_linux_plugin.cc"
)

apply_standard_settings(${PLUGIN_NAME})
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL)
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
)
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)

set(nativeflow_bridge_linux_bundled_libraries
  ""
  PARENT_SCOPE
)
