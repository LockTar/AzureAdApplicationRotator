var gulp = require('gulp');
var del = require('del');

var psModulesFolderName = 'ps_modules'

var paths = {
  extension : {
    psModules : psModulesFolderName + '/',
    removeAzureAdApplication : {
      v1 : 'Remove-AzureAdApplicationKeyRotator/Remove-AzureAdApplicationKeyRotatorV1/'
    }
  },
  code : {
    root : '../',
    removeAzureAdApplication : {
      v1 : '../Scripts/Remove-AzureAdApplicationKeyRotator/v1/'
    },
    vstsAzureHelpers : '../Scripts/VstsAzureHelpers/'
  }
}

function cleanRemoveAzureAdApplication() {
  console.log('Delete everything in ' + paths.extension.removeAzureAdApplication.v1);
  return del([
    paths.extension.removeAzureAdApplication.v1 + 'Scripts',
    paths.extension.removeAzureAdApplication.v1 + psModulesFolderName
  ]);
}

function buildPsModulesRemoveAzureAdApplication() {
  console.log('Fill the ps modules');
  // gulp.src(paths.extension.psModules + 'AzureRM/**/*')
  //   .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v1 + psModulesFolderName + "/AzureRM"));

  gulp.src(paths.extension.psModules + 'TelemetryHelper/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v1 + psModulesFolderName + "/TelemetryHelper"));
    
  gulp.src(paths.extension.psModules + 'VstsAzureRestHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v1 + psModulesFolderName + "/VstsAzureRestHelpers_"));

  gulp.src(paths.extension.psModules + 'VstsTaskSdk/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v1 + psModulesFolderName + "/VstsTaskSdk"));

  return gulp.src(paths.code.vstsAzureHelpers + '**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v1 + psModulesFolderName + "/VstsAzureHelpers"));
}

function buildScriptFilesAzureADApplication() {
  console.log('Fill ' + paths.extension.removeAzureAdApplication.v1 + ' Scripts from ' + paths.code.removeAzureAdApplication.v1);
  return gulp.src(paths.code.removeAzureAdApplication.v1 + '**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplication.v1 + 'Scripts'));
}

var taskName = "RemoveAdApplication";
gulp.task('clean:' + taskName, cleanRemoveAzureAdApplication);
gulp.task('clean', cleanRemoveAzureAdApplication);

gulp.task('build:' + taskName, gulp.parallel(buildPsModulesRemoveAzureAdApplication, buildScriptFilesAzureADApplication));
gulp.task('build', gulp.parallel(buildPsModulesRemoveAzureAdApplication, buildScriptFilesAzureADApplication));

gulp.task('reset:' + taskName, gulp.series('clean:' + taskName, 'build:' + taskName));
gulp.task('reset', gulp.series('clean:' + taskName, 'build:' + taskName));