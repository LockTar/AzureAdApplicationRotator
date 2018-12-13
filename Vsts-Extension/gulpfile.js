'use strict';

var gulp = require('gulp');
var HubRegistry = require('gulp-hub');
var del = require('del');

/* load some files into the registry */
var hub = new HubRegistry(['gulp-tasks/**/*.js']);

/* tell gulp to use the tasks just loaded */
gulp.registry(hub);


function buildReadmeFile() {
  console.log('Copy the readme file to the root of the extension');
  return gulp.src('../Readme.md')
    .pipe(gulp.dest('./'));
}

function cleanReadmeFile() {
  console.log('Delete the readme file from the root of the extension');
  return del([
    './Readme.md',
  ]);
}

gulp.task('clean', gulp.series(cleanReadmeFile, gulp.parallel('clean')));
gulp.task('default', gulp.series(buildReadmeFile, gulp.parallel('build')));
gulp.task('build', gulp.series(buildReadmeFile, gulp.parallel('build')));
gulp.task('reset', gulp.series(cleanReadmeFile, buildReadmeFile, gulp.parallel('reset')));