cmake_minimum_required(VERSION 3.16)
project(FriendlyFreyaNative LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_executable(friendly_freya src/main.cpp)

if(WIN32)
  find_package(SDL2 CONFIG REQUIRED)
  target_link_libraries(friendly_freya PRIVATE SDL2::SDL2 SDL2::SDL2main opengl32)
  target_compile_definitions(friendly_freya PRIVATE _USE_MATH_DEFINES)
else()
  find_package(PkgConfig REQUIRED)
  pkg_check_modules(SDL2 REQUIRED sdl2)
  target_include_directories(friendly_freya PRIVATE ${SDL2_INCLUDE_DIRS})
  target_link_directories(friendly_freya PRIVATE ${SDL2_LIBRARY_DIRS})
  target_compile_options(friendly_freya PRIVATE ${SDL2_CFLAGS_OTHER})
  target_link_libraries(friendly_freya PRIVATE ${SDL2_LIBRARIES} GL)
endif()

