cmake_minimum_required(VERSION 2.8.8)
project(client_qt)

include_directories("${PROJECT_BINARY_DIR}")
include_directories("${PROJECT_SOURCE_DIR}")

find_package(Qt5Widgets REQUIRED)
find_package(Qt5Network REQUIRED)
find_package(Qt5Core REQUIRED)

set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTORCC ON)

add_executable(client_qt config.cpp dock_connexion.cpp dock_discussion.cpp dock_invitation.cpp dock_login.cpp joueur_hors_jeu.cpp main.cpp messages.cpp q_requests.cpp q_value_stream.cpp tarotv.cpp value.cpp vue_jhj.cpp ressource.qrc)
target_link_libraries(client_qt Qt5::Widgets Qt5::Network Qt5::Core)