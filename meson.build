project(
  'io.elementary.music',
  'vala', 'c',
  version: '7.1.0',
  meson_version: '>=0.58.0'
)

gnome = import('gnome')
i18n = import('i18n')
fs = import('fs')

add_global_arguments('-DGETTEXT_PACKAGE="@0@"'.format (meson.project_name()), language:'c')

config_data = configuration_data()
config_data.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
config_data.set_quoted('GETTEXT_PACKAGE', meson.project_name())

message('Environment variables loading...')
env_vars = fs.read('.env').split('\n')
env = environment()
foreach var : env_vars
    if var == ''
        continue
    endif
    message(var)
    full = var.split('=')
    env.set(full[0], full[1])
    config_data.set_quoted(full[0], full[1])
endforeach

config_file = configure_file(
    input: 'src/Config.vala.in',
    output: '@BASENAME@',
    configuration: config_data
)

granite_dep = dependency('granite-7')
gstreamer_dep = dependency('gstreamer-1.0')
gstreamer_pbutils_dep = dependency('gstreamer-pbutils-1.0')
gstreamer_tag_dep = dependency('gstreamer-tag-1.0')
gtk_dep = dependency('gtk4')
soup_dep = dependency('libsoup-3.0')
json_glib_dep = dependency('json-glib-1.0')

dependencies = [
    granite_dep,
    gstreamer_dep,
    gstreamer_pbutils_dep,
    gstreamer_tag_dep,
    gtk_dep,
    soup_dep,
    json_glib_dep
]

gnome.post_install(glib_compile_schemas: true)

subdir('data')
subdir('po')
subdir('src')
