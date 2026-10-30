local M = {}

function M.get_header_template()
	return [[#pragma once

class {{MODULE_NAME}} {
public:
    {{MODULE_NAME}}();

    /* Rule of five: if you need one, better add all! */
    /* Destructor, copy constructor, copy assignment, move constructor, move assignment. */
    // ~{{MODULE_NAME}}() = default;
    // {{MODULE_NAME}}(const {{MODULE_NAME}}&) = default;
    // {{MODULE_NAME}}& operator=(const {{MODULE_NAME}}&) = default;
    // {{MODULE_NAME}}({{MODULE_NAME}}&&) noexcept = default;
    // {{MODULE_NAME}}& operator=({{MODULE_NAME}}&&) noexcept = default;


private:

};]]
end

function M.get_cpp_template()
	return [[#include "{{MODULE_NAME}}.h"


{{MODULE_NAME}}::{{MODULE_NAME}}() {
}


]]
end

function M.get_header_template_with_qt6()
	return [[#pragma once

#include <QObject>

class {{MODULE_NAME}} : public QObject {
    Q_OBJECT
public:
    explicit {{MODULE_NAME}}(QObject* parent = nullptr);

    /* Rule of five: if you need one, better add all! */
    /* Destructor, copy constructor, copy assignment, move constructor, move assignment. */
    // ~{{MODULE_NAME}}() = default;
    // {{MODULE_NAME}}(const {{MODULE_NAME}}&) = default;
    // {{MODULE_NAME}}& operator=(const {{MODULE_NAME}}&) = default;
    // {{MODULE_NAME}}({{MODULE_NAME}}&&) noexcept = default;
    // {{MODULE_NAME}}& operator=({{MODULE_NAME}}&&) noexcept = default;


private:

};]]
end

function M.get_cpp_template_with_qt6()
	return [[#include "{{MODULE_NAME}}.h"


{{MODULE_NAME}}::{{MODULE_NAME}}(QObject* parent)
    : QObject(parent) {
}


]]
end

function M.get_test_cpp_template()
	return [[#include "{{MODULE_NAME}}.h"
#include <gtest/gtest.h>
#include <memory>

TEST(BasicSetupTest, GoogleTestWorks) {
    EXPECT_EQ(1, 1);
    EXPECT_TRUE(true);
}

class {{MODULE_NAME}}Test : public ::testing::Test {
protected:
    void SetUp() override {
	test_instance_ = std::make_unique<{{MODULE_NAME}}>();
    }
    void TearDown() override {
    }
public:
    std::unique_ptr<{{MODULE_NAME}}> test_instance_;
};

]]
end

function M.get_test_cmake_template()
	return [[set(TEST_TARGET {{MODULE_NAME}}Test)

file(GLOB TEST_SOURCES ${CMAKE_CURRENT_SOURCE_DIR}/*.cpp)

add_executable(${TEST_TARGET} ${TEST_SOURCES})
target_include_directories(${TEST_TARGET} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}
    ${CMAKE_SOURCE_DIR}/externals/googletest/googletest/include)

target_compile_features(${TEST_TARGET} PUBLIC cxx_std_{{CPP_VERSION}})
target_link_libraries(${TEST_TARGET} PRIVATE
    # You can link everything you may need here
    {{MODULE_NAME}}
    gtest
    gtest_main
)

include(GoogleTest)
gtest_discover_tests(${TEST_TARGET})
]]
end

function M.get_main_template(version)
	if version and version >= 23 then
		return [[#include <print>
#include <string>
#include "version.h"

#ifdef _WIN32
    #include <windows.h>
#else
    #include <sys/file.h>
    #include <unistd.h>
    #include <cerrno>
#endif

extern const char* embedded_version;

int main() {
    std::string welcome_to_ahoicpp = "\nAhoiCpp is a tool for setting a C++ development environment in Neovim.\n\
\nC++ is a challenging language, specially for newcomers.\n\
This is my take on making it easier to hop along.\n\
\nAhoiCpp can set up classes, cmake files, app entrypoints and\n\
even creates a python script for building your project.";
    std::println("{}", welcome_to_ahoicpp);
    return 0;
}
]]
	end
	return [[#include <iostream>
#include <string>
#include "version.h"

#ifdef _WIN32
    #include <windows.h>
#else
    #include <sys/file.h>
    #include <unistd.h>
    #include <cerrno>
#endif

extern const char* embedded_version;

int main() {
    std::string welcome_to_ahoicpp = "\nAhoiCpp is a tool for setting a C++ development environment in Neovim.\n\
\nC++ is a challenging language, specially for newcomers.\n\
This is my take on making it easier to hop along.\n\
\nAhoiCpp can set up classes, cmake files, app entrypoints and\n\
even creates a python script for building your project.";
	std::cout << welcome_to_ahoicpp << '\n';
    return 0;
}
]]
end

function M.get_main_template_qt()
	return [[#include "version.h"
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QObject>
#include <QString>

#ifdef _WIN32
    #include <windows.h>
#else
    #include <sys/file.h>
    #include <unistd.h>
    #include <cerrno>
#endif

extern const char* embedded_version;

class app_controller : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool text_visible
               READ text_visible
               WRITE set_text_visible
               NOTIFY text_visible_changed)
    Q_PROPERTY(QString headline
               READ headline
               CONSTANT)
    Q_PROPERTY(QString body
               READ body
               CONSTANT)

public:
    explicit app_controller(QObject* parent = nullptr) : QObject(parent) {}

    bool text_visible() const {
        return text_visible_;
    }

    void set_text_visible(bool visible) {
        if (visible == text_visible_) {
            return;
        }
        text_visible_ = visible;
        emit text_visible_changed();
    }

    QString headline() const {
        return QStringLiteral(
            "AhoiCpp is a tool for setting a C++ development environment in Neovim.");
    }

    QString body() const {
        return QStringLiteral(
            "C++ is a challenging language, specially for newcomers.\n"
            "This is my take on making it easier to hop along.\n"
            "\n"
            "AhoiCpp can set up classes, cmake files, app entrypoints and\n"
            "even creates a python script for building your project.");
    }

public slots:
    void toggle_text() {
        set_text_visible(!text_visible_);
    }

    void clear_text() {
        set_text_visible(false);
    }

    void quit() {
        QCoreApplication::quit();
    }

signals:
    void text_visible_changed();

private:
    bool text_visible_ = false;
};

#include "{{PROJECT_NAME}}.moc"

int main(int argc, char* argv[]) {
    QGuiApplication app(argc, argv);

    app_controller controller;

    QQmlApplicationEngine engine;
    engine.rootContext()->setContextProperty("app", &controller);

    QObject::connect(
        &engine,
        &QQmlApplicationEngine::objectCreationFailed,
        &app,
        []() {
            QCoreApplication::exit(-1);
        },
        Qt::QueuedConnection);

    engine.loadFromModule("{{PROJECT_NAME}}Qml", "Main");

    return app.exec();
}
]]
end

function M.get_main_qml_template_qt()
	return [[import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 900
    height: 640
    title: "{{PROJECT_NAME}}"
    color: "#1a1b26"

    readonly property color bg:           "#1a1b26"
    readonly property color bg_soft:      "#1f2335"
    readonly property color fg:           "#c0caf5"
    readonly property color fg_dim:       "#a9b1d6"
    readonly property color comment:      "#565f89"
    readonly property color pastel_blue:  "#7aa2f7"
    readonly property color pastel_pink:  "#f7768e"
    readonly property color pastel_purple:"#bb9af7"
    readonly property color pastel_cyan:  "#7dcfff"
    readonly property color pastel_green: "#9ece6a"

    readonly property bool text_visible: app.text_visible

    background: Rectangle {
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: "#1a1b26" }
            GradientStop { position: 0.5; color: "#1f2335" }
            GradientStop { position: 1.0; color: "#1a1b26" }
        }
    }

    Rectangle {
        width: 420; height: 420; radius: 210
        x: -140; y: -140
        color: window.pastel_purple
        opacity: 0.10
    }
    Rectangle {
        width: 360; height: 360; radius: 180
        x: window.width - 220
        y: window.height - 240
        color: window.pastel_pink
        opacity: 0.08
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: Math.min(parent.width - 96, 640)
        spacing: 28

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            width: 72; height: 24; radius: 12
            color: window.bg_soft
            border.color: Qt.rgba(0.34, 0.37, 0.54, 0.4)
            border.width: 1

            RowLayout {
                anchors.centerIn: parent
                spacing: 6
                Repeater {
                    model: [window.pastel_pink, "#e0af68", window.pastel_green]
                    Rectangle {
                        width: 8; height: 8; radius: 4
                        color: modelData
                        opacity: 0.85
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: text_col.implicitHeight + 56
            Layout.preferredHeight: window.text_visible ? implicitHeight : 0
            radius: 16
            color: window.bg_soft
            border.color: Qt.rgba(0.34, 0.37, 0.54, 0.35)
            border.width: 1
            visible: window.text_visible || opacity > 0.0
            opacity: window.text_visible ? 1.0 : 0.0
            clip: true
            Behavior on opacity { NumberAnimation { duration: 220 } }

            Rectangle {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 1
                height: 1
                radius: parent.radius
                color: Qt.rgba(0.75, 0.79, 0.96, 0.06)
            }

            ColumnLayout {
                id: text_col
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.margins: 28
                spacing: 14

                Text {
                    Layout.fillWidth: true
                    text: app.headline
                    color: window.fg
                    font.pixelSize: 17
                    font.family: "JetBrains Mono"
                    wrapMode: Text.WordWrap
                    lineHeight: 1.4
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Qt.rgba(0.34, 0.37, 0.54, 0.35)
                }

                Text {
                    Layout.fillWidth: true
                    text: app.body
                    color: window.fg_dim
                    font.pixelSize: 15
                    font.family: "JetBrains Mono"
                    wrapMode: Text.WordWrap
                    lineHeight: 1.5
                }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 14

            Button {
                id: toggle_btn
                implicitWidth: 160
                implicitHeight: 44
                text: window.text_visible ? "Clear" : "Click Me"

                contentItem: Text {
                    text: toggle_btn.text
                    color: window.text_visible ? window.pastel_cyan : "#1a1b26"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    font.family: "JetBrains Mono"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 10

                    gradient: window.text_visible ? null : gradient_primary
                    color: window.text_visible
                           ? (toggle_btn.pressed
                                ? Qt.rgba(0.49, 0.81, 1.0, 0.12)
                                : toggle_btn.hovered
                                  ? Qt.rgba(0.49, 0.81, 1.0, 0.07)
                                  : "transparent")
                           : "transparent"

                    border.color: window.text_visible
                                  ? Qt.rgba(0.49, 0.81, 1.0,
                                            toggle_btn.hovered ? 0.55 : 0.30)
                                  : "transparent"
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }

                    Gradient {
                        id: gradient_primary
                        GradientStop { position: 0.0; color: window.pastel_blue }
                        GradientStop { position: 1.0; color: window.pastel_purple }
                    }
                }

                onClicked: {
                    if (window.text_visible) {
                        app.clear_text()
                    } else {
                        app.toggle_text()
                    }
                }
            }

            Button {
                id: close_btn
                text: "Close"
                implicitWidth: 120
                implicitHeight: 44

                contentItem: Text {
                    text: close_btn.text
                    color: window.pastel_pink
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    font.family: "JetBrains Mono"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 10
                    color: close_btn.pressed
                           ? Qt.rgba(1.0, 0.46, 0.56, 0.14)
                           : close_btn.hovered
                             ? Qt.rgba(1.0, 0.46, 0.56, 0.08)
                             : "transparent"
                    border.color: Qt.rgba(1.0, 0.46, 0.56,
                                          close_btn.hovered ? 0.6 : 0.35)
                    border.width: 1
                    Behavior on color { ColorAnimation { duration: 150 } }
                    Behavior on border.color { ColorAnimation { duration: 150 } }
                }

                onClicked: app.quit()
            }
        }
    }
}
]]
end

function M.get_parent_cmake_template()
	return [[cmake_minimum_required(VERSION 3.28)

if(DEFINED VERSION_ARG)
    set(PROJECT_VERSION ${VERSION_ARG})
else()
    set(PROJECT_VERSION "99.99.99") 
endif()
if(DEFINED COMPANY_ARG)
	set(PROJECT_COMPANY ${COMPANY_ARG})
else()
	set(PROJECT_COMPANY "AhoiTools") 
endif()
if(DEFINED DESCRIPTION_ARG)
	set(PROJECT_DESCRIPTION ${DESCRIPTION_ARG})
else()
	set(PROJECT_DESCRIPTION "Your project is owned by AhoiTools") 
endif()

project({{PROJECT_NAME}} VERSION ${PROJECT_VERSION})
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
set(VER_MAJOR ${PROJECT_VERSION_MAJOR})
set(VER_MINOR ${PROJECT_VERSION_MINOR})
set(VER_PATCH ${PROJECT_VERSION_PATCH})
set(VERSION ${PROJECT_VERSION})
set(COMPANY ${PROJECT_COMPANY})
set(DESCRIPTION ${PROJECT_DESCRIPTION})
set(PRODUCT ${PROJECT_NAME})
string(TIMESTAMP COPYRIGHT_YEAR "%Y")
set(COPYRIGHT "Copyright ${COPYRIGHT_YEAR}")

string(TIMESTAMP BUILD_TIMESTAMP "%Y-%m-%dT%H:%M:%SZ" UTC)
string(TIMESTAMP BUILD_DATE "%Y%m%d")

include(AhoiCppProject.cmake)
include(AhoiCppExternals.cmake)
add_library(ahoicpp_externals INTERFACE)

foreach(PATH ${AHOICPP_EXTERNALS_INCLUDE_PATHS})
    file(GLOB EXPANDED_PATHS ${PATH})
    foreach(EXPANDED ${EXPANDED_PATHS})
        if(IS_DIRECTORY ${EXPANDED})
            target_include_directories(ahoicpp_externals INTERFACE ${EXPANDED})
        endif()
    endforeach()
    if(NOT PATH MATCHES "\\*")
        if(EXISTS ${PATH})
            target_include_directories(ahoicpp_externals INTERFACE ${PATH})
        endif()
    endif()
endforeach()
add_subdirectory(App)
]]
end

function M.get_app_cmake_template()
	return [[cmake_minimum_required(VERSION 3.28)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/version.h.in
    ${CMAKE_CURRENT_SOURCE_DIR}/version.h
    @ONLY
)

add_executable({{PROJECT_NAME}} src/{{PROJECT_NAME}}.cpp)
target_include_directories({{PROJECT_NAME}} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

include(AhoiCppSubdirs.cmake)

add_library(ahoicpp_externals_iface INTERFACE)
target_link_libraries(ahoicpp_externals_iface INTERFACE ahoicpp_externals)
target_link_libraries(ahoicpp_externals_iface INTERFACE ${AHOICPP_EXTERNALS_TARGETS})
target_compile_features({{PROJECT_NAME}} PUBLIC cxx_std_{{CPP_VERSION}})

target_link_libraries({{PROJECT_NAME}} PRIVATE
    ahoicpp_externals_iface
)

if(WIN32)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/version.rc.in
        ${CMAKE_CURRENT_SOURCE_DIR}/version.rc
        @ONLY
    )
    target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/version.rc)
else()
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/version.c.in
        ${CMAKE_CURRENT_SOURCE_DIR}/version.c
        @ONLY
    )
    target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/version.c)
endif()
]]
end

function M.get_app_cmake_template_qt()
	return [[cmake_minimum_required(VERSION 3.28)

configure_file(
    ${CMAKE_CURRENT_SOURCE_DIR}/version.h.in
    ${CMAKE_CURRENT_SOURCE_DIR}/version.h
    @ONLY
)

find_package(Qt6 6.5 REQUIRED COMPONENTS Quick Gui Widgets)
qt_standard_project_setup()

if(QT_KNOWN_POLICY_QTP0001)
    qt_policy(SET QTP0001 NEW)
endif()

qt_add_executable({{PROJECT_NAME}} src/{{PROJECT_NAME}}.cpp)
target_include_directories({{PROJECT_NAME}} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})

file(GLOB_RECURSE PROJECT_QML_FILES CONFIGURE_DEPENDS
    ${CMAKE_CURRENT_SOURCE_DIR}/qml/*.qml
)

foreach(f IN LISTS PROJECT_QML_FILES)
    file(RELATIVE_PATH _rel "${CMAKE_CURRENT_SOURCE_DIR}/qml" "${f}")
    set_source_files_properties("${f}" PROPERTIES
        QT_RESOURCE_ALIAS "${_rel}")
endforeach()

qt_add_qml_module(
    {{PROJECT_NAME}}
    URI ${PROJECT_NAME}Qml
    VERSION 1.0
    QML_FILES ${PROJECT_QML_FILES}
)

include(AhoiCppSubdirs.cmake)

add_library(ahoicpp_externals_interface INTERFACE)
target_link_libraries(ahoicpp_externals_interface INTERFACE ahoicpp_externals)
target_link_libraries(ahoicpp_externals_interface INTERFACE ${AHOICPP_EXTERNALS_TARGETS})

target_link_libraries(${PROJECT_NAME} PRIVATE
    ahoicpp_externals_interface
    Qt6::Quick
    Qt6::Gui
)

target_compile_features(${PROJECT_NAME} PUBLIC cxx_std_23)

if(WIN32)
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/version.rc.in
        ${CMAKE_CURRENT_SOURCE_DIR}/version.rc
        @ONLY
    )
    target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/version.rc)
else()
    configure_file(
        ${CMAKE_CURRENT_SOURCE_DIR}/version.c.in
        ${CMAKE_CURRENT_SOURCE_DIR}/version.c
        @ONLY
    )
    target_sources(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/version.c)
endif()
]]
end

function M.get_module_cmake_template()
	return [[add_library({{MODULE_NAME}} STATIC src/{{MODULE_NAME}}.cpp)
target_link_libraries({{MODULE_NAME}} ahoicpp_externals)
target_compile_features({{MODULE_NAME}} PUBLIC cxx_std_{{CPP_VERSION}})
target_include_directories({{MODULE_NAME}} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/{{MODULE_NAME}})
]]
end

function M.get_module_cmake_template_with_qt6()
	return [[find_package(Qt6 REQUIRED COMPONENTS Core)

add_library({{MODULE_NAME}} STATIC src/{{MODULE_NAME}}.cpp include/{{MODULE_NAME}}/{{MODULE_NAME}}.h)
set_target_properties({{MODULE_NAME}} PROPERTIES AUTOMOC ON AUTOUIC ON AUTORCC ON)
target_link_libraries({{MODULE_NAME}} ahoicpp_externals Qt6::Core)
target_compile_features({{MODULE_NAME}} PUBLIC cxx_std_{{CPP_VERSION}})
target_include_directories({{MODULE_NAME}} PUBLIC ${CMAKE_CURRENT_SOURCE_DIR}/include/{{MODULE_NAME}})
]]
end

function M.get_ahoi_externals_template()
	return [[#Created automagically by AhoiCpp. You can modify this file to add new external libraries to your project. You just have to follow the pattern:
set(AHOICPP_EXTERNALS_INCLUDE_PATHS
    "${CMAKE_CURRENT_SOURCE_DIR}/externals"
    "${CMAKE_CURRENT_SOURCE_DIR}/externals/*/include"
    "${CMAKE_CURRENT_SOURCE_DIR}/externals/*/src"
)
]]
end

function M.get_buildscript()
	return [[import os
import sys
import platform
import shutil


def run_cmake_on_linux(build_type: str, version: str = "99.99.99", company: str = "", description: str = ""):
    if version == "":
        version = "99.99.99"
    build_command = f"""
        mkdir -p build &&
        cd build &&
        cmake .. -DCMAKE_BUILD_TYPE={build_type} -D VERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON &&
        ln -sf build/compile_commands.json ../ &&
        make -j$(nproc) > build.log 2>&1

        """
    if shutil.which("ninja") is not None:
        build_command = f"""
        mkdir -p build &&
        cd build &&
        cmake .. -DCMAKE_BUILD_TYPE={build_type} -G Ninja -D VERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON &&
        ln -sf build/compile_commands.json ../ &&
        ninja > build.log 2>&1
        """

    status = os.system(build_command)
    if status != 0:
        exit_code = os.waitstatus_to_exitcode(status)
        sys.exit(exit_code)
    sys.exit(0)


def run_cmake_on_windows(build_type: str, version: str = "99.99.99", company: str = "", description: str = ""):
    if version == "":
        version = "99.99.99"

    pre_build_command = f"""
    if not exist build mkdir build;
    """
    os.system(pre_build_command)

    build_command = f"""
        cd build && cmake .. -D VERSION_ARG="{version}"
        """

    if shutil.which("ninja") is not None:
        build_command = f"""
        cd build && cmake .. -G Ninja -DCMAKE_BUILD_TYPE={build_type} -DVERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && ninja > build.log 2>&1
        """
    elif shutil.which("make") is not None:
        build_command = f"""
        cd build && cmake .. -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE={build_type} -DVERSION_ARG="{version}" -D COMPANY_ARG="{company}" -D DESCRIPTION_ARG={description} -DCMAKE_EXPORT_COMPILE_COMMANDS=ON && make -j $env:NUMBER_OF_PROCESSORS > build.log 2>&1
        """

    else:
        print("Ninja not found. Will produce Visual Studio Solution. Please open in Visual Studio or compile it with MSBuild")

    status = os.system(build_command)

    if status != 0:
        exit_code = os.waitstatus_to_exitcode(status)
        sys.exit(exit_code)

    sys.exit(0)


def run_app(build_type: str, version: str = "", company: str = "", description: str = ""):
    operating_system = platform.system()
    match operating_system:
        case "Linux":
            print("Linux detected, let us run the build.")
            run_cmake_on_linux(build_type, version, company, description)
        case "Windows":
            print("Windows detected, let us generate a Visual Studio Solution file.")
            run_cmake_on_windows(build_type, version, company, description)


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Welcome to AhoiCpp build process. Pick your build or just press enter to go fast.")
        print("[Enter]  FastBuild")
        print("[0]      Release")
        print("[1]      Debug")
        build_selection = input()

        match(build_selection):
            case "":
                run_app("Release", "")
            case "0":
                print("You selected Release. Please add a version to your build. Format recommended: XX.XX.XX. Hint: you can just press enter and leave it empty.")
                version = input()
                run_app("Release", version)
            case "1":
                print("Build as Debug")
                run_app("RelWithDebInfo", "")
            case _:
                print("Invalid input. Bye.")
    elif (sys.argv[1] == "debug"):
        version = sys.argv[2] if len(sys.argv) > 2 else "99.99.99"
        company = sys.argv[3] if len(sys.argv) > 3 else "AhoiTools"
        description = sys.argv[4] if len(
            sys.argv) > 4 else "Your project is owned by AhoiTools."
        run_app("RelWithDebInfo", version, company, description)
    else:
        version = sys.argv[2] if len(sys.argv) > 2 else "99.99.99"
        company = sys.argv[3] if len(sys.argv) > 3 else "AhoiTools"
        description = sys.argv[4] if len(
            sys.argv) > 4 else "Your project is owned by AhoiTools."
        run_app("Release", version, company, description)
]]
end

function M.get_version_c_in()
	return [[
const char* embedded_version =
    "@PROJECT_NAME@ version: @VERSION@\n"
    "Build type: @CMAKE_BUILD_TYPE@\n"
    "Copyright: @COPYRIGHT@\n"
    "Company: @COMPANY@\n";
]]
end

function M.get_version_h_in()
	return [[#pragma once

#define PROJECT_VERSION "@VERSION@"
#define PROJECT_VERSION_MAJOR @PROJECT_VERSION_MAJOR@
#define PROJECT_VERSION_MINOR @PROJECT_VERSION_MINOR@
#define PROJECT_VERSION_PATCH @PROJECT_VERSION_PATCH@
]]
end

function M.get_version_rc_in()
	return [[#include <windows.h>

VS_VERSION_INFO VERSIONINFO
FILEVERSION    @VER_MAJOR@,@VER_MINOR@,@VER_PATCH@
PRODUCTVERSION @VER_MAJOR@,@VER_MINOR@,@VER_PATCH@
FILEFLAGSMASK 0x3fL
FILEFLAGS 0x0L
FILEOS VOS_NT_WINDOWS32
FILETYPE VFT_APP
FILESUBTYPE 0x0L
BEGIN
    BLOCK "StringFileInfo"
    BEGIN
        BLOCK "040904b0"
        BEGIN
            VALUE "CompanyName", "@COMPANY@"
            VALUE "FileDescription", "@DESCRIPTION@"
            VALUE "FileVersion", "@VERSION@"
            VALUE "ProductName", "@PRODUCT@"
            VALUE "ProductVersion", "@VERSION@"
            VALUE "LegalCopyright", "@COPYRIGHT@"
        END
    END
    BLOCK "VarFileInfo"
    BEGIN
        VALUE "Translation", 0x409, 1200
    END
END
]]
end

function M.get_externals_readme()
	return [[# External dependencies

This directory is intended for third-party libraries cloned from Git.

## How to use

1. Clone a dependency (use `<leader>cpe on Neovim` and paste the git url, or clone manually from externals directory).

2. Integrate into your build:
- If it uses CMake: add `add_subdirectory(externals/<library-name>)` to the CMakeLists.txt file of the module that needs the external library.
- If it is a header-only library: add `target_include_directories(your_target PRIVATE externals/<library-name>/include)` or the path to the correspondent header.
- Due to C++ complexity and lack of standardization, some external libraries may need extra work to be integrated. Even in modern commercial IDEs it is not supposed to work out of the box.

## Example with nlohmann-json (header-only):
- Run `<leader>cpe`.
- Paste `https://github.com/nlohmann/json.git` to the dialog prompt.
- Then add the following to the target modules CMakeLists.txt: `target_include_directories(<YourTargetModuleName> PUBLIC ${CMAKE_SOURCE_DIR}/externals/json/include)`.
- If everything is fine, you can go to `<YourTargetModuleName>.cpp` and put `#include "nlohmann/json.hpp"` at the top of it.
- Now compile it with `<leader>cpc`.
- Note: For other libraries that need extra compilation, you may have to also paste `target_link_libraries(<YourTargetModuleName> <YourClonedExternalLibrary>)`
]]
end

function M.get_gitignore()
	return [[build/
cross-build/
compile_commands.json

.vscode/
.idea/
*.swp
*.swo
*~

.DS_Store
Thumbs.db

*.o
*.obj
*.exe
*.out
*.app
*.so
*.dylib
*.dll

CMakeCache.txt
CMakeFiles/
cmake_install.cmake
!AhoiCppExternals.cmake
!AhoiCppProject.cmake
!AhoiCppSubdirs.cmake

App/version.h
App/version.c
App/version.rc

__pycache__/
*.pyc
]]
end

function M.get_clangd_template()
	return [[CompileFlags:
  Add: [-Wall, -Wextra]

Diagnostics:
  ClangTidy:
    Add:
      - bugprone-*
      - performance-*
      - cppcoreguidelines-special-member-functions
      - modernize-use-override
      - modernize-use-nullptr
      - modernize-use-using
      - readability-braces-around-statements
      - readability-container-size-empty
    Remove: []
    CheckOptions: {}
]]
end

function M.get_readme_template()
	return [[# {{PROJECT_NAME}}

Bootstrapped with AhoiCpp
]]
end

function M.get_project_json_template()
	return [[{
	"project_name": "{{PROJECT_NAME}}",
	"build_path": "./build/App/",
	"execution_path": "./build/App/",
	"build_as": "release",
	"version": "99.99.99",
	"company": "AhoiTools",
	"description": "Your project is owned by AhoiTools",
	"use_qt6": false
}]]
end

function M.get_cross_compile_dockerfile_template()
	return [[FROM ubuntu:26.04

ARG DEBIAN_FRONTEND=noninteractive
ARG LLVM_MINGW_VERSION=20260616
ARG LLVM_MINGW_UBUNTU=22.04

ENV XWIN=/opt/xwin
ENV PATH="/root/.cargo/bin:${PATH}"
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    cmake \
    ninja-build \
    git \
    pkg-config \
    g++-16-x86-64-linux-gnu \
    gcc-16-x86-64-linux-gnu \
    g++-16-aarch64-linux-gnu \
    gcc-16-aarch64-linux-gnu \
    gcc-16 \
    g++-16 \
    clang \
    lld \
    llvm \
    clang-tools \
    cargo \
    rustc \
    libjpeg8 \
    libwebp7 \
    libwebpmux3 \
    libwebpdemux2 \
    libpng16-16 \
    libtiff6 \
    unzip \
    wget \
    curl \
    xz-utils \
    file \
    && rm -rf /var/lib/apt/lists/*

RUN ARCH=$(uname -m) && \
    echo "Detected host architecture: $ARCH" && \
    case "$ARCH" in \
        aarch64|arm64) SUFFIX="aarch64" ;; \
        x86_64|amd64) SUFFIX="x86_64" ;; \
        *) echo "Unsupported architecture: $ARCH"; exit 1 ;; \
    esac && \
    LLVM_MINGW_DIR="/opt/llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-${LLVM_MINGW_UBUNTU}-${SUFFIX}" && \
    LLVM_MINGW_ARCHIVE="llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-ubuntu-${LLVM_MINGW_UBUNTU}-${SUFFIX}.tar.xz" && \
    wget -q "https://github.com/mstorsjo/llvm-mingw/releases/download/${LLVM_MINGW_VERSION}/${LLVM_MINGW_ARCHIVE}" && \
    tar -xf "${LLVM_MINGW_ARCHIVE}" -C /opt && \
    rm "${LLVM_MINGW_ARCHIVE}" && \
    printf '%s\n' "${SUFFIX}" > /opt/llvm-mingw-arch.txt && \
    test -x "${LLVM_MINGW_DIR}/bin/clang++"

RUN SUFFIX=$(cat /opt/llvm-mingw-arch.txt) && \
    LLVM_MINGW_DIR="/opt/llvm-mingw-${LLVM_MINGW_VERSION}-ucrt-${LLVM_MINGW_UBUNTU}-${SUFFIX}" && \
    printf '#!/usr/bin/env bash\nexec "%s/bin/clang++" --target=x86_64-w64-mingw32 "$@"\n' "${LLVM_MINGW_DIR}" > /usr/local/bin/mingw-clang++ && \
    printf '#!/usr/bin/env bash\nexec "%s/bin/clang++" --target=aarch64-w64-mingw32 "$@"\n' "${LLVM_MINGW_DIR}" > /usr/local/bin/mingw-arm64-clang++ && \
    chmod +x /usr/local/bin/mingw-clang++ /usr/local/bin/mingw-arm64-clang++

RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-16 100 \
    && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-16 100 \
    && update-alternatives --install /usr/bin/cc cc /usr/bin/gcc-16 100 \
    && update-alternatives --install /usr/bin/c++ c++ /usr/bin/g++-16 100

RUN cargo install xwin --locked && \
    rm -rf /opt/xwin /opt/.xwin-cache && \
    cd /opt && \
    xwin --accept-license splat --output /opt/xwin && \
    test -f /opt/xwin/crt/include/vector && \
    test -f /opt/xwin/crt/lib/x86_64/libcmt.lib && \
    test -f /opt/xwin/crt/lib/x86_64/oldnames.lib && \
    test -f /opt/xwin/sdk/lib/ucrt/x86_64/ucrt.lib && \
    find /opt/xwin -iname 'msvcrt.lib' -print -quit | grep -q .

RUN command -v clang-cl && \
    command -v lld-link && \
    command -v llvm-rc && \
    clang-cl --version && \
    lld-link --version && \
    xwin --version

CMD ["/bin/bash"]
]]
end

function M.get_toolchain_x86_64_linux()
	return [[set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR x86_64_linux)

find_program(CROSS_GCC x86_64-linux-gnu-gcc-16)
find_program(CROSS_GXX x86_64-linux-gnu-g++-16)

if(NOT CROSS_GCC OR NOT CROSS_GXX)
    message(FATAL_ERROR "x86_64 Linux cross-compiler not found")
endif()

set(CMAKE_C_COMPILER ${CROSS_GCC})
set(CMAKE_CXX_COMPILER ${CROSS_GXX})

set(CMAKE_CXX_STANDARD {{CPP_VERSION}})

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)

set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
]]
end

function M.get_toolchain_aarch64_linux()
	return [[set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64_linux)

find_program(CROSS_GCC aarch64-linux-gnu-gcc-16)
find_program(CROSS_GXX aarch64-linux-gnu-g++-16)

if(NOT CROSS_GCC OR NOT CROSS_GXX)
    message(FATAL_ERROR "ARM64 Linux cross-compiler not found")
endif()

set(CMAKE_C_COMPILER ${CROSS_GCC})
set(CMAKE_CXX_COMPILER ${CROSS_GXX})

set(CMAKE_CXX_STANDARD {{CPP_VERSION}})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_EXE_LINKER_FLAGS_INIT "-static-libstdc++ -static-libgcc")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)
]]
end

function M.get_toolchain_x86_64_windows()
	return [[set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR x86_64)

set(XWIN_ROOT "/opt/xwin")
set(LLVM_ROOT "/usr/lib/llvm-21")
set(TARGET_TRIPLE "x86_64-pc-windows-msvc")

set(XWIN_CRT_INCLUDE "${XWIN_ROOT}/crt/include")
set(XWIN_CRT_LIB "${XWIN_ROOT}/crt/lib/x86_64")

set(XWIN_SDK_INCLUDE "${XWIN_ROOT}/sdk/include")
set(XWIN_SDK_LIB "${XWIN_ROOT}/sdk/lib")

set(XWIN_SDK_UCRT_INCLUDE "${XWIN_SDK_INCLUDE}/ucrt")
set(XWIN_SDK_SHARED_INCLUDE "${XWIN_SDK_INCLUDE}/shared")
set(XWIN_SDK_UM_INCLUDE "${XWIN_SDK_INCLUDE}/um")
set(XWIN_SDK_WINRT_INCLUDE "${XWIN_SDK_INCLUDE}/winrt")
set(XWIN_SDK_CPPWINRT_INCLUDE "${XWIN_SDK_INCLUDE}/cppwinrt")

set(XWIN_SDK_UCRT_LIB "${XWIN_SDK_LIB}/ucrt/x86_64")
set(XWIN_SDK_UM_LIB "${XWIN_SDK_LIB}/um/x86_64")

if(NOT EXISTS "${XWIN_CRT_INCLUDE}/vector")
    message(FATAL_ERROR "xwin C++ headers not found: ${XWIN_CRT_INCLUDE}")
endif()

if(NOT EXISTS "${XWIN_SDK_UM_INCLUDE}/windows.h")
    message(FATAL_ERROR "Windows SDK headers not found: ${XWIN_SDK_UM_INCLUDE}")
endif()

if(NOT EXISTS "${XWIN_CRT_LIB}/libcmt.lib")
    message(FATAL_ERROR "xwin CRT libraries not found: ${XWIN_CRT_LIB}")
endif()

if(NOT EXISTS "${XWIN_CRT_LIB}/oldnames.lib")
    message(FATAL_ERROR "xwin oldnames.lib not found: ${XWIN_CRT_LIB}")
endif()

if(NOT EXISTS "${LLVM_ROOT}/bin/clang-cl")
    message(FATAL_ERROR "clang-cl not found: ${LLVM_ROOT}/bin/clang-cl")
endif()

if(NOT EXISTS "${LLVM_ROOT}/bin/lld-link")
    message(FATAL_ERROR "lld-link not found: ${LLVM_ROOT}/bin/lld-link")
endif()

set(CMAKE_C_COMPILER "${LLVM_ROOT}/bin/clang-cl")
set(CMAKE_CXX_COMPILER "${LLVM_ROOT}/bin/clang-cl")
set(CMAKE_LINKER "${LLVM_ROOT}/bin/lld-link")

set(CMAKE_C_COMPILER_TARGET "${TARGET_TRIPLE}")
set(CMAKE_CXX_COMPILER_TARGET "${TARGET_TRIPLE}")

set(CMAKE_RC_COMPILER "${LLVM_ROOT}/bin/llvm-rc")
set(CMAKE_AR "${LLVM_ROOT}/bin/llvm-lib")
set(CMAKE_C_COMPILER_AR "${LLVM_ROOT}/bin/llvm-lib")
set(CMAKE_CXX_COMPILER_AR "${LLVM_ROOT}/bin/llvm-lib")

set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

set(CMAKE_POLICY_DEFAULT_CMP0091 NEW)
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDLL")

set(CMAKE_C_FLAGS_INIT "/imsvc ${XWIN_CRT_INCLUDE} /imsvc ${XWIN_SDK_UCRT_INCLUDE} /imsvc ${XWIN_SDK_SHARED_INCLUDE} /imsvc ${XWIN_SDK_UM_INCLUDE} /imsvc ${XWIN_SDK_WINRT_INCLUDE} /imsvc ${XWIN_SDK_CPPWINRT_INCLUDE}")

set(CMAKE_CXX_FLAGS_INIT "${CMAKE_C_FLAGS_INIT} -clang:-Wno-error=character-conversion")
set(CMAKE_RC_FLAGS_INIT "-I${XWIN_CRT_INCLUDE} -I${XWIN_SDK_UCRT_INCLUDE} -I${XWIN_SDK_SHARED_INCLUDE} -I${XWIN_SDK_UM_INCLUDE} -I${XWIN_SDK_WINRT_INCLUDE} -I${XWIN_SDK_CPPWINRT_INCLUDE}")

set(CMAKE_EXE_LINKER_FLAGS_INIT "-fuse-ld=lld-link /libpath:${XWIN_CRT_LIB} /libpath:${XWIN_SDK_UCRT_LIB} /libpath:${XWIN_SDK_UM_LIB}")

set(CMAKE_SHARED_LINKER_FLAGS_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT}")
set(CMAKE_MODULE_LINKER_FLAGS_INIT "${CMAKE_EXE_LINKER_FLAGS_INIT}")

set(CMAKE_CXX_STANDARD {{CPP_VERSION}})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)
]]
end

function M.get_toolchain_aarch64_windows()
	return [[set(CMAKE_SYSTEM_NAME Windows)
set(CMAKE_SYSTEM_PROCESSOR arm64)

execute_process(
    COMMAND uname -m
    OUTPUT_VARIABLE HOST_ARCH
    OUTPUT_STRIP_TRAILING_WHITESPACE
)

if(HOST_ARCH STREQUAL "x86_64")
    set(LLVM_SUFFIX "x86_64")
else()
    set(LLVM_SUFFIX "aarch64")
endif()

set(LLVM_MINGW_PATH "/opt/llvm-mingw-20260616-ucrt-ubuntu-22.04-${LLVM_SUFFIX}")

if(NOT EXISTS "${LLVM_MINGW_PATH}/bin/clang")
    message(FATAL_ERROR "llvm-mingw not found at ${LLVM_MINGW_PATH}")
endif()

set(CMAKE_C_COMPILER ${LLVM_MINGW_PATH}/bin/clang)
set(CMAKE_CXX_COMPILER ${LLVM_MINGW_PATH}/bin/clang++)

set(CMAKE_C_COMPILER_TARGET aarch64-w64-mingw32)
set(CMAKE_CXX_COMPILER_TARGET aarch64-w64-mingw32)

set(CMAKE_RC_COMPILER ${LLVM_MINGW_PATH}/bin/llvm-rc)
set(CMAKE_AR ${LLVM_MINGW_PATH}/bin/llvm-ar)
set(CMAKE_RANLIB ${LLVM_MINGW_PATH}/bin/llvm-ranlib)
set(CMAKE_LINKER ${LLVM_MINGW_PATH}/bin/lld)

set(CMAKE_FIND_ROOT_PATH ${LLVM_MINGW_PATH})
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE ONLY)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE ONLY)

set(CMAKE_CXX_STANDARD {{CPP_VERSION}})
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(CMAKE_EXE_LINKER_FLAGS_INIT "-static -fuse-ld=lld")
set(CMAKE_CXX_FLAGS_INIT "-stdlib=libc++ -static")
set(CMAKE_CXX_STANDARD_LIBRARIES_INIT "-lc++ -lc++abi -lunwind -lmingw32 -lmingwex -lmsvcrt -lucrt")
]]
end

function M.get_start_devcontainer_script()
	return [[if [ -f /.dockerenv ]; then
    echo "You are already in a Docker container. Aborting."
    exit 1
fi

docker build -t devcontainer .
docker run -it --rm -v $(pwd):/workspace -w /workspace --user $(id -u):$(id -g) devcontainer
]]
end

function M.get_cross_compile_in_devcontainer_script()
	return [[if [ ! -f /.dockerenv ]; then
    echo "You are not in a Docker container. Aborting."
    exit 1
fi

for config in "linux-x86_64:toolchain-x86_64-linux.cmake" "linux-arm64:toolchain-aarch64-linux.cmake" "windows-x86_64:toolchain-windows-x86_64.cmake" "windows-arm64:toolchain-windows-arm64.cmake"; do
    build_dir="${config%%:*}"
    toolchain_file="${config##*:}"
    echo "Building ${build_dir}..."
    mkdir -p "cross-build/${build_dir}" || exit 1
    cd "cross-build/${build_dir}" || exit 1
    cmake ../.. -DCMAKE_TOOLCHAIN_FILE="../../cmake/${toolchain_file}" -DCMAKE_BUILD_TYPE="Release" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -G Ninja || exit 1
    ninja > build.log 2>&1
    cd ../.. || exit 1
done
]]
end

return M
