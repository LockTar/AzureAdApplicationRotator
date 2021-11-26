var gulp = require('gulp');
var del = require('del');

var psModulesFolderName = 'ps_modules'

var paths = {
  extension : {
    psModules : '../scripts/Common/v1/',
    setAzureAdApplicationKeyRotator : {
      v1 : 'Set-AzureAdApplicationKeyRotator/Set-AzureAdApplicationKeyRotatorV1/'
    }
  },
  code : {
    root : '../',
    scripts : '../scripts/',
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
    paths.extension.setAzureAdApplicationKeyRotator.v1 + 'CoreAz.ps1',
    paths.extension.setAzureAdApplicationKeyRotator.v1 + 'Utility.ps1',
    paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName
  ]);
}

function buildPsModulesSetAzureAdApplicationKeyRotator() {
  console.log('Fill the ps modules');
  
  gulp.src(paths.code.scripts + 'CustomAzureDevOpsAzureHelpers/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/CustomAzureDevOpsAzureHelpers"));

  gulp.src(paths.extension.psModules + 'TlsHelper_/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/TlsHelper_"));

  gulp.src(paths.extension.psModules + 'VstsAzureHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsAzureHelpers_"));

  gulp.src(paths.extension.psModules + 'VstsAzureRestHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsAzureRestHelpers_"));

  return gulp.src(paths.extension.psModules + 'VstsTaskSdk/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + psModulesFolderName + "/VstsTaskSdk"));
}

function buildScriptFilesAzureADApplication() {
  gulp.src(paths.code.scripts + 'CoreAz.ps1')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1));
  gulp.src(paths.code.scripts + 'Utility.ps1')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1));
  
  console.log('Fill ' + paths.extension.setAzureAdApplicationKeyRotator.v1 + ' scripts from ' + paths.code.setAzureAdApplicationKeyRotator.v1);
  return gulp.src(paths.code.setAzureAdApplicationKeyRotator.v1 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplicationKeyRotator.v1 + 'scripts'));
}

var taskName = "SetAzureAdApplicationKeyRotator";
gulp.task('clean:' + taskName, cleanSetAzureAdApplicationKeyRotator);
gulp.task('clean', cleanSetAzureAdApplicationKeyRotator);

gulp.task('build:' + taskName, gulp.parallel(buildPsModulesSetAzureAdApplicationKeyRotator, buildScriptFilesAzureADApplication));
gulp.task('build', gulp.parallel(buildPsModulesSetAzureAdApplicationKeyRotator, buildScriptFilesAzureADApplication));

gulp.task('reset:' + taskName, gulp.series('clean:' + taskName, 'build:' + taskName));
gulp.task('reset', gulp.series('clean:' + taskName, 'build:' + taskName));
