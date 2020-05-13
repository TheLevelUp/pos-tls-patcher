#tool "nuget:?package=GitVersion.CommandLine&version=5.0.0"
#addin "Cake.FileHelpers&version=3.2.0"
#addin "Cake.AWS.S3&version=0.6.8"
#tool "nuget:?package=OpenCover&version=4.7.922"
#tool "nuget:?package=ReportGenerator&version=4.2.15"
#tool "nuget:?package=coveralls.io&version=1.4.2"
#tool "nuget:?package=Microsoft.TestPlatform&version=16.2.0"
#addin "nuget:?package=Cake.Coveralls&version=0.10.0"

//////////////////////////////////////////////////////////////////////
// ARGUMENTS
//////////////////////////////////////////////////////////////////////

var target = Argument("target", "Default");
var configuration = Argument("configuration", "Debug");
var solution = GetFiles("*.sln").First();

//////////////////////////////////////////////////////////////////////
// APPVEYOR SETUP
//////////////////////////////////////////////////////////////////////

if(AppVeyor.IsRunningOnAppVeyor)
{
    Setup(context =>
    {
        var settings = Context.CreateDownloadSettings().SetRegion("us-east-1").SetBucketName("levelup-pos-build");
        System.Threading.Tasks.Task.WaitAll(new[] 
        {
            // Configure nuget sources
            S3Download(new FilePath(EnvironmentVariable("APPDATA") + "\\NuGet\\NuGet.Config"), "NuGet.Config", settings),
            // Retrieve cert
            S3Download(new FilePath("Certificates.p12"), "Certificates.p12", settings)
        });
        
        // Pass version info to AppVeyor
        GitVersion(new GitVersionSettings{
            ArgumentCustomization = args => args.Append("-verbosity Warn"),
            OutputType = GitVersionOutput.BuildServer,
            NoFetch = true
        });
    });
}

//////////////////////////////////////////////////////////////////////
// TASKS
//////////////////////////////////////////////////////////////////////

Task("Clean")
    .Does(() =>
{
    CleanDirectories("**/bin");
    CleanDirectories("**/obj");
});

Task("Restore")
    .IsDependentOn("Clean")
    .Does(() =>
{
    NuGetRestore(solution);
});

Task("Build")
    .IsDependentOn("Restore")
    .Does(() =>
{
    MSBuild(solution, new MSBuildSettings {
        Configuration = configuration,
        EnvironmentVariables = new Dictionary<string, string> 
        {  
            { "GitVersion_NoFetchEnabled", "true" } 
        },
        ArgumentCustomization = arg => arg.AppendSwitch("/p:DebugType","=","Full")
    });
});

//////////////////////////////////////////////////////////////////////
// TASK TARGETS
//////////////////////////////////////////////////////////////////////

Task("Default")
    .IsDependentOn("Build");

//////////////////////////////////////////////////////////////////////
// EXECUTION
//////////////////////////////////////////////////////////////////////

RunTarget(target);
