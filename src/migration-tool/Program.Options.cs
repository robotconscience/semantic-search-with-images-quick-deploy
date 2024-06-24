using System.CommandLine;
using System.CommandLine.Invocation;

internal static partial class Program
{
    private static readonly Option<string> s_sourceSearchEndpoint =
        new(name: "--sourcesearchendpoint", description: "The source Azure AI Search service endpoint containing data to be cloned.");
    private static readonly Option<string> s_sourceSearchKey =
        new(name: "--sourcesearchkey", description: "The source Azure AI Search service key.");
    private static readonly Option<string> s_sourceSearchIndexName =
        new(name: "--sourcesearchindexname", description: "The source Azure AI Search service index name to be cloned.");
    private static readonly Option<string> s_targetSearchEndpoint =
        new(name: "--targetsearchendpoint", description: "The target Azure AI Search service endpoint into which data will be cloned.");
    private static readonly Option<string> s_targetSearchKey =
        new(name: "--targetsearchkey", description: "The target Azure AI Search service key.");

    private static readonly RootCommand s_rootCommand =
        new(description:"""
        Clone data from one Azure AI Search service (source) to a second (target).
        The source index name will be used in the target service.
        """)
        {
            s_sourceSearchEndpoint,
            s_sourceSearchKey,
            s_sourceSearchIndexName,
            s_targetSearchEndpoint,
            s_targetSearchKey,
        };

    private static AppOptions GetParsedAppOptions(InvocationContext context) => new(
        SourceSearchEndpoint: context.ParseResult.GetValueForOption(s_sourceSearchEndpoint),
        SourceSearchKey: context.ParseResult.GetValueForOption(s_sourceSearchKey),
        SourceSearchIndexName: context.ParseResult.GetValueForOption(s_sourceSearchIndexName),
        TargetSearchEndpoint: context.ParseResult.GetValueForOption(s_targetSearchEndpoint),
        TargetSearchKey: context.ParseResult.GetValueForOption(s_targetSearchKey),
        Console: context.Console);
}