var gulp = require('gulp');
var del = require('del');

var psModulesFolderName = 'ps_modules'

var paths = {
  extension : {
    psModules : psModulesFolderName + '/',
    setAzureAdApplication : {
      v1 : 'Set-AzureAdApplicationKeyRotator/Set-AzureAdApplicationKeyRotatorV1/'
    }
  },
  code : {
    root : '../',
    setAzureAdApplication : {
      v1 : '../scripts/Set-AzureAdApplicationKeyRotator/v1/'
    },
    vstsAzureHelpers : '../scripts/VstsAzureHelpers/'
  }
}

function cleanSetAzureAdApplication() {
  console.log('Delete everything in ' + paths.extension.setAzureAdApplication.v1);
  return del([
    paths.extension.setAzureAdApplication.v1 + 'scripts',
    paths.extension.setAzureAdApplication.v1 + psModulesFolderName
  ]);
}

function buildPsModulesSetAzureAdApplication() {
  console.log('Fill the ps modules');
  gulp.src(paths.extension.psModules + 'TelemetryHelper/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v1 + psModulesFolderName + "/TelemetryHelper"));
    
  gulp.src(paths.extension.psModules + 'VstsAzureRestHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v1 + psModulesFolderName + "/VstsAzureRestHelpers_"));

  gulp.src(paths.extension.psModules + 'VstsTaskSdk/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v1 + psModulesFolderName + "/VstsTaskSdk"));

  return gulp.src(paths.code.vstsAzureHelpers + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v1 + psModulesFolderName + "/VstsAzureHelpers"));
}

function buildScriptFilesAzureADApplication() {
  console.log('Fill ' + paths.extension.setAzureAdApplication.v1 + ' scripts from ' + paths.code.setAzureAdApplication.v1);
  gulp.src(paths.code.setAzureAdApplication.v1 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v1 + 'scripts'));
  
  console.log('Fill ' + paths.extension.setAzureAdApplication.v1 + ' scripts from ' + paths.code.newAzureAdApplication.v1);
  gulp.src(paths.code.newAzureAdApplication.v1 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v1 + 'scripts'));

  console.log('Fill ' + paths.extension.setAzureAdApplication.v1 + ' scripts from ' + paths.code.getAzureAdApplication.v1);
  return gulp.src(paths.code.getAzureAdApplication.v1 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v1 + 'scripts'));
}

var taskName = "SetAdApplication";
gulp.task('clean:' + taskName, cleanSetAzureAdApplication);
gulp.task('clean', cleanSetAzureAdApplication);

gulp.task('build:' + taskName, gulp.parallel(buildPsModulesSetAzureAdApplication, buildScriptFilesAzureADApplication));
gulp.task('build', gulp.parallel(buildPsModulesSetAzureAdApplication, buildScriptFilesAzureADApplication));

gulp.task('reset:' + taskName, gulp.series('clean:' + taskName, 'build:' + taskName));
gulp.task('reset', gulp.series('clean:' + taskName, 'build:' + taskName));