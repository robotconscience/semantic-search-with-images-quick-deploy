internal record class AppOptions(
    string? SourceSearchEndpoint,
    string? SourceSearchKey,
    string? SourceSearchIndexName,
    string? TargetSearchEndpoint,
    string? TargetSearchKey,
    System.CommandLine.IConsole Console) : AppConsole(Console);

internal record class AppConsole(System.CommandLine.IConsole Console);