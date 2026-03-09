# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "media_browser_plugin")
project(${PROJECT_NAME} LANGUAGES CXX)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "media_browser_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "media_browser_plugin.cpp"
)

# Any new header files that you add to the plugin should be added here.
list(APPEND PLUGIN_HEADERS
  "media_browser_plugin.h"
)

# The name of the library target. Any new source files that you add to the
# plugin should be added to PLUGIN_SOURCES in CMakeLists.txt. You can then
# edit the CMakeLists.txt file for your plugin to add any additional
# dependencies or include directories.
add_library(${PLUGIN_NAME} SHARED
  "media_browser_plugin.cpp"
)

# Apply a standard set of build settings that are configured for all
# plugins. This can be removed for plugins that need different build
# settings.
apply_standard_plugin_settings(${PLUGIN_NAME})

# Any new dependencies that you add to the plugin should be added here.
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter)
target_link_libraries(${PLUGIN_NAME} PRIVATE PkgConfig::PC_PKG)

# Source include directories that are needed for this plugin.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")

# The plugin's build settings can be modified here. For example, to add
# preprocessor definitions:
# target_compile_definitions(${PLUGIN_NAME} PRIVATE DEFINITION_NAME)

# The plugin's build settings can be modified here. For example, to add
# additional dependencies:
# target_link_libraries(${PLUGIN_NAME} PRIVATE library_name)
