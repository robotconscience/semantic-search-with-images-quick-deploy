using Azure.Identity;
using Azure.Search.Documents;
using Azure.Search.Documents.Models;
using System.CommandLine;

s_rootCommand.SetHandler(
    async (context) => 
    {
        var options = GetParsedAppOptions(context);

        // Setup the target
        await CloneIndexInTarget(options);

        // Clone the data
        await CloneDataInTarget(options);

        context.Console.WriteLine($"Index cloned from source search index to target successfully.");
    });

return await s_rootCommand.InvokeAsync(args);

static async ValueTask CloneIndexInTarget(AppOptions options)
{
    var sourceIndexClient = await GetSourceSearchIndexClientAsync(options);
    var targetIndexClient = await GetTargetSearchIndexClientAsync(options);

    var indexToClone = await sourceIndexClient.GetIndexAsync(options.SourceSearchIndexName);
    var result = await targetIndexClient.CreateOrUpdateIndexAsync(indexToClone);

    options.Console.WriteLine($"Result of target create: {result}");
    options.Console.WriteLine($"Created index {options.SourceSearchIndexName} in target based on source definition.");
}

static async ValueTask CloneDataInTarget(AppOptions options)
{
    var sourceClient = await GetSourceSearchClientAsync(options);
    var targetClient = await GetTargetSearchClientAsync(options);

    string lastObjectId = "0";
    var nextBatchResponse = await GetBatchOfDocumentsFromSource(options, lastObjectId);
    while (nextBatchResponse.TotalCount > 0)
    {
        // Save to a temporary list to upload to target in batch
        List<Dictionary<string, object>> documentsToUpload = [];
        await foreach (SearchResult<Dictionary<string, object>> result in nextBatchResponse.GetResultsAsync())
        {
            documentsToUpload.Add(result.Document);
        }
        // Upload batch
        await targetClient.UploadDocumentsAsync(documentsToUpload);
        // Get the next batch
        lastObjectId = documentsToUpload?.Last()["ObjectID"].ToString() ?? "0";
        nextBatchResponse = await GetBatchOfDocumentsFromSource(options, lastObjectId);

        options.Console.WriteLine($"Cloned batch of {documentsToUpload?.Count} through Object ID {lastObjectId}.");
    }
}

static async Task<SearchResults<Dictionary<string, object>>> GetBatchOfDocumentsFromSource(AppOptions options, string lastObjectId)
{
    var sourceClient = await GetSourceSearchClientAsync(options);

    SearchOptions searchOptions = new()
    {
        IncludeTotalCount = true,
        Filter = SearchFilter.Create($"ObjectID gt {lastObjectId}"),
        Size = 1000, // Uploads to Azure AI Search are limited to batches of 1000
        OrderBy = { "ObjectID" } 
    };
    return await sourceClient.SearchAsync<Dictionary<string, object>>("*", searchOptions);
}
