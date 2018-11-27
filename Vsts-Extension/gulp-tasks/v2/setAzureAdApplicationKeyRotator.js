var gulp = require('gulp');
var del = require('del');

var psModulesFolderName = 'ps_modules'

var paths = {
  extension : {
    psModules : psModulesFolderName + '/',
    setAzureAdApplication : {
      v2 : 'Set-AzureAdApplication/Set-AzureAdApplicationV2/'
    }
  },
  code : {
    root : '../',
    setAzureAdApplication : {
      v2 : '../scripts/Set-AzureAdApplication/v2/'
    },
    newAzureAdApplication : {
      v2 : '../scripts/New-AzureAdApplication/v2/'
    },
    getAzureAdApplication : {
      v2 : '../scripts/Get-AzureAdApplication/v2/'
    },
    vstsAzureHelpers : '../scripts/VstsAzureHelpers/'
  }
}

function cleanSetAzureAdApplication() {
  console.log('Delete everything in ' + paths.extension.setAzureAdApplication.v2);
  return del([
    paths.extension.setAzureAdApplication.v2 + 'scripts',
    paths.extension.setAzureAdApplication.v2 + psModulesFolderName
  ]);
}

function buildPsModulesSetAzureAdApplication() {
  console.log('Fill the ps modules');
  gulp.src(paths.extension.psModules + 'TelemetryHelper/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v2 + psModulesFolderName + "/TelemetryHelper"));
    
  gulp.src(paths.extension.psModules + 'VstsAzureRestHelpers_/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v2 + psModulesFolderName + "/VstsAzureRestHelpers_"));

  gulp.src(paths.extension.psModules + 'VstsTaskSdk/**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v2 + psModulesFolderName + "/VstsTaskSdk"));

  return gulp.src(paths.code.vstsAzureHelpers + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v2 + psModulesFolderName + "/VstsAzureHelpers"));
}

function buildScriptFilesAzureADApplication() {
  console.log('Fill ' + paths.extension.setAzureAdApplication.v2 + ' scripts from ' + paths.code.setAzureAdApplication.v2);
  gulp.src(paths.code.setAzureAdApplication.v2 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v2 + 'scripts'));
  
  console.log('Fill ' + paths.extension.setAzureAdApplication.v2 + ' scripts from ' + paths.code.newAzureAdApplication.v2);
  gulp.src(paths.code.newAzureAdApplication.v2 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v2 + 'scripts'));

  console.log('Fill ' + paths.extension.setAzureAdApplication.v2 + ' scripts from ' + paths.code.getAzureAdApplication.v2);
  return gulp.src(paths.code.getAzureAdApplication.v2 + '**/*')
    .pipe(gulp.dest(paths.extension.setAzureAdApplication.v2 + 'scripts'));
}

var taskName = "SetAdApplication";
gulp.task('clean:' + taskName, cleanSetAzureAdApplication);
gulp.task('clean', cleanSetAzureAdApplication);

gulp.task('build:' + taskName, gulp.parallel(buildPsModulesSetAzureAdApplication, buildScriptFilesAzureADApplication));
gulp.task('build', gulp.parallel(buildPsModulesSetAzureAdApplication, buildScriptFilesAzureADApplication));

gulp.task('reset:' + taskName, gulp.series('clean:' + taskName, 'build:' + taskName));
gulp.task('reset', gulp.series('clean:' + taskName, 'build:' + taskName));