'use strict';

var gulp = require('gulp');
var HubRegistry = require('gulp-hub');

/* load some files into the registry */
var hub = new HubRegistry(['gulp-tasks/**/*.js']);

/* tell gulp to use the tasks just loaded */
gulp.registry(hub);


function buildReadmeFile() {
    console.log('Copy the readme file to the root of the extension');
    return gulp.src('../Readme.md')
      .pipe(gulp.dest('./'));
}

gulp.task('default', gulp.series(buildReadmeFile, gulp.parallel('build')));