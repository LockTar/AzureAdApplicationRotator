var gulp = require('gulp');
var del = require('del');

var psModulesFolderName = 'ps_modules'

var paths = {
  extension : {
    psModules : psModulesFolderName + '/',
    setAzureAdApplicationKeyRotator : {
      v1 : 'Set-AzureAdApplicationKeyRotator/Set-AzureAdApplicationKeyRotatorV1/'
    }
  },
  code : {
    root : '../',
    setAzureAdApplicationKeyRotator : {
      v1 : '../scripts/Set-AzureAdApplicationKeyRotator/v1/'
    },
    vstsAzureHelpers : '../scripts/VstsAzureHelpers/'
  }
}

function cleanSetAzureAdApplicationKeyRotator() {
  console.log('Delete everything in ' + paths.extension.setAzureAdApplicationKeyRotator.v1);
  return del([
    paths.extension.setAzureAdApplicationKeyRotator.v1 + 'scripts',
    paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName
  ]);
}

function buildPsModulesSetAzureAdApplicationKeyRotator() {
  console.log('Fill the ps modules');
  gulp.src(paths.extension.psModules + 'TelemetryHelper/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/TelemetryHelper"));
    
  gulp.src(paths.extension.psModules + 'VstsAzureRestHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsAzureRestHelpers_"));

  gulp.src(paths.extension.psModules + 'VstsTaskSdk/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsTaskSdk"));

  return gulp.src(paths.code.vstsAzureHelpers + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsAzureHelpers"));
}

function buildScriptFilesAzureADApplication() {
  console.log('Fill ' + paths.extension.setAzureAdApplicationKeyRotator.v1 + ' scripts from ' + paths.code.setAzureAdApplicationKeyRotator.v1);
  return gulp.src(paths.code.setAzureAdApplicationKeyRotator.v1 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + 'scripts'));
}

var taskName = "SetAdApplication";
gulp.task('clean:' + taskName, cleanSetAzureAdApplicationKeyRotator);
gulp.task('clean', cleanSetAzureAdApplicationKeyRotator);

gulp.task('build:' + taskName, gulp.parallel(buildPsModulesSetAzureAdApplicationKeyRotator, buildScriptFilesAzureADApplication));
gulp.task('build', gulp.parallel(buildPsModulesSetAzureAdApplicationKeyRotator, buildScriptFilesAzureADApplication));

gulp.task('reset:' + taskName, gulp.series('clean:' + taskName, 'build:' + taskName));
gulp.task('reset', gulp.series('clean:' + taskName, 'build:' + taskName));