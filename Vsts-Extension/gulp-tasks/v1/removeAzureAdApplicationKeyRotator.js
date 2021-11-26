var gulp = require('gulp');
var del = require('del');

var psModulesFolderName = 'ps_modules'

var paths = {
  extension : {
    psModules : '../scripts/Common/v1/',
    removeAzureAdApplicationKeyRotator : {
      v1 : 'Remove-AzureAdApplicationKeyRotator/Remove-AzureAdApplicationKeyRotatorV1/'
    }
  },
  code : {
    root : '../',
    scripts : '../scripts/',
    removeAzureAdApplicationKeyRotator : {
      v1 : '../scripts/Remove-AzureAdApplicationKeyRotator/v1/'
    },
    vstsAzureHelpers : '../scripts/VstsAzureHelpers/'
  }
}

function cleanRemoveAzureAdApplicationKeyRotator() {
  console.log('Delete everything in ' + paths.extension.removeAzureAdApplicationKeyRotator.v1);
  return del([
    paths.extension.removeAzureAdApplicationKeyRotator.v1 + 'scripts',
    paths.extension.removeAzureAdApplicationKeyRotator.v1 + 'CoreAz.ps1',
    paths.extension.removeAzureAdApplicationKeyRotator.v1 + 'Utility.ps1',
    paths.extension.removeAzureAdApplicationKeyRotator.v1 + psModulesFolderName
  ]);
}

function buildPsModulesRemoveAzureAdApplicationKeyRotator() {
  console.log('Fill the ps modules');
  
  gulp.src(paths.code.scripts + 'CustomAzureDevOpsAzureHelpers/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/CustomAzureDevOpsAzureHelpers"));

  gulp.src(paths.extension.psModules + 'TlsHelper_/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/TlsHelper_"));

  gulp.src(paths.extension.psModules + 'VstsAzureHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsAzureHelpers_"));

  gulp.src(paths.extension.psModules + 'VstsAzureRestHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsAzureRestHelpers_"));

  return gulp.src(paths.extension.psModules + 'VstsTaskSdk/**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsTaskSdk"));
}

function buildScriptFilesAzureADApplication() {
  gulp.src(paths.code.scripts + 'CoreAz.ps1')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1));
  gulp.src(paths.code.scripts + 'Utility.ps1')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1));
  
  console.log('Fill ' + paths.extension.removeAzureAdApplicationKeyRotator.v1 + ' scripts from ' + paths.code.removeAzureAdApplicationKeyRotator.v1);
  return gulp.src(paths.code.removeAzureAdApplicationKeyRotator.v1 + '**/*')
    .pipe(gulp.dest(paths.extension.removeAzureAdApplicationKeyRotator.v1 + 'scripts'));
}

var taskName = "RemoveAzureAdApplicationKeyRotator";
gulp.task('clean:' + taskName, cleanRemoveAzureAdApplicationKeyRotator);
gulp.task('clean', cleanRemoveAzureAdApplicationKeyRotator);

gulp.task('build:' + taskName, gulp.parallel(buildPsModulesRemoveAzureAdApplicationKeyRotator, buildScriptFilesAzureADApplication));
gulp.task('build', gulp.parallel(buildPsModulesRemoveAzureAdApplicationKeyRotator, buildScriptFilesAzureADApplication));

gulp.task('reset:' + taskName, gulp.series('clean:' + taskName, 'build:' + taskName));
gulp.task('reset', gulp.series('clean:' + taskName, 'build:' + taskName));
