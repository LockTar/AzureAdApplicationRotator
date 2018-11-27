var gulp = require('gulp');
var del = require('del');

var psModulesFolderName = 'ps_modules'

var paths = {
  extension : {
    psModules : psModulesFolderName + '/',
    removeAzureAdApplication : {
      v2 : 'Remove-AzureAdApplication/Remove-AzureAdApplicationV2/'
    }
  },
  code : {
    root : '../',
    removeAzureAdApplication : {
      v2 : '../scripts/Remove-AzureAdApplication/v2/'
    },
    vstsAzureHelpers : '../scripts/VstsAzureHelpers/'
  }
}

function cleanRemoveAzureAdApplication() {
  console.log('Delete everything in ' + paths.extension.removeAzureAdApplication.v2);
  return del([
    paths.extension.removeAzureAdApplication.v2 + 'scripts',
    paths.extension.removeAzureAdApplication.v2 + psModulesFolderName
  ]);
}

function buildPsModulesRemoveAzureAdApplication() {
  console.log('Fill the ps modules');
  // gulp.src(paths.extension.psModules + 'AzureRM/**/*')
  //   .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v2 + psModulesFolderName + "/AzureRM"));

  gulp.src(paths.extension.psModules + 'TelemetryHelper/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v2 + psModulesFolderName + "/TelemetryHelper"));
    
  gulp.src(paths.extension.psModules + 'VstsAzureRestHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v2 + psModulesFolderName + "/VstsAzureRestHelpers_"));

  gulp.src(paths.extension.psModules + 'VstsTaskSdk/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v2 + psModulesFolderName + "/VstsTaskSdk"));

  return gulp.src(paths.code.vstsAzureHelpers + '**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v2 + psModulesFolderName + "/VstsAzureHelpers"));
}

function buildScriptFilesAzureADApplication() {
  console.log('Fill ' + paths.extension.removeAzureAdApplication.v2 + ' scripts from ' + paths.code.removeAzureAdApplication.v2);
  return gulp.src(paths.code.removeAzureAdApplication.v2 + '**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v2 + 'scripts'));
}

var taskName = "RemoveAdApplication";
gulp.task('clean:' + taskName, cleanRemoveAzureAdApplication);
gulp.task('clean', cleanRemoveAzureAdApplication);

gulp.task('build:' + taskName, gulp.parallel(buildPsModulesRemoveAzureAdApplication, buildScriptFilesAzureADApplication));
gulp.task('build', gulp.parallel(buildPsModulesRemoveAzureAdApplication, buildScriptFilesAzureADApplication));

gulp.task('reset:' + taskName, gulp.series('clean:' + taskName, 'build:' + taskName));
gulp.task('reset', gulp.series('clean:' + taskName, 'build:' + taskName));