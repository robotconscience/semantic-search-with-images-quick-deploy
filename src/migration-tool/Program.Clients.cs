using Azure;
using Azure.Search.Documents;
using Azure.Search.Documents.Indexes;

internal static partial class Program
{
    private static SearchIndexClient? s_sourceSearchIndexClient;
    private static SearchClient? s_sourceSearchClient;
    private static SearchIndexClient? s_targetSearchIndexClient;
    private static SearchClient? s_targetSearchClient;

    private static readonly SemaphoreSlim s_sourceSearchIndexLock = new(1);
    private static readonly SemaphoreSlim s_sourceSearchLock = new(1);
    private static readonly SemaphoreSlim s_targetSearchIndexLock = new(1);
    private static readonly SemaphoreSlim s_targetSearchLock = new(1);

    private static Task<SearchIndexClient> GetSourceSearchIndexClientAsync(AppOptions options) =>
        GetLazyClientAsync<SearchIndexClient>(options, s_sourceSearchIndexLock, async o =>
        {
            if (s_sourceSearchIndexClient is null)
            {
                var endpoint = o.SourceSearchEndpoint;
                ArgumentNullException.ThrowIfNullOrEmpty(endpoint);
                var key = o.SourceSearchKey;
                ArgumentNullException.ThrowIfNullOrEmpty(key);

                s_sourceSearchIndexClient = new SearchIndexClient(
                    new Uri(endpoint),
                    new AzureKeyCredential(key));
            }

            await Task.CompletedTask;

            return s_sourceSearchIndexClient;
        });

    private static Task<SearchClient> GetSourceSearchClientAsync(AppOptions options) =>
        GetLazyClientAsync<SearchClient>(options, s_sourceSearchLock, async o =>
        {
            if (s_sourceSearchClient is null)
            {
                var endpoint = o.SourceSearchEndpoint;
                ArgumentNullException.ThrowIfNullOrEmpty(endpoint);
                var indexName = o.SourceSearchIndexName;
                ArgumentNullException.ThrowIfNullOrEmpty(indexName);
                var key = o.SourceSearchKey;
                ArgumentNullException.ThrowIfNullOrEmpty(key);

                s_sourceSearchClient = new SearchClient(
                    new Uri(endpoint),
                    indexName,
                    new AzureKeyCredential(key));
            }

            await Task.CompletedTask;

            return s_sourceSearchClient;
        });

    private static Task<SearchIndexClient> GetTargetSearchIndexClientAsync(AppOptions options) =>
        GetLazyClientAsync<SearchIndexClient>(options, s_targetSearchIndexLock, async o =>
        {
            if (s_targetSearchIndexClient is null)
            {
                var endpoint = o.TargetSearchEndpoint;
                ArgumentNullException.ThrowIfNullOrEmpty(endpoint);
                var key = o.TargetSearchKey;
                ArgumentNullException.ThrowIfNullOrEmpty(key);

                s_targetSearchIndexClient = new SearchIndexClient(
                    new Uri(endpoint),
                    new AzureKeyCredential(key));
            }

            await Task.CompletedTask;

            return s_targetSearchIndexClient;
        });

    private static Task<SearchClient> GetTargetSearchClientAsync(AppOptions options) =>
        GetLazyClientAsync<SearchClient>(options, s_targetSearchLock, async o =>
        {
            if (s_targetSearchClient is null)
            {
                var endpoint = o.TargetSearchEndpoint;
                ArgumentNullException.ThrowIfNullOrEmpty(endpoint);
                // Reusing source index name
                var indexName = o.SourceSearchIndexName;
                ArgumentNullException.ThrowIfNullOrEmpty(indexName);
                var key = o.TargetSearchKey;
                ArgumentNullException.ThrowIfNullOrEmpty(key);

                s_targetSearchClient = new SearchClient(
                    new Uri(endpoint),
                    indexName,
                    new AzureKeyCredential(key));
            }

            await Task.CompletedTask;

            return s_targetSearchClient;
        });


    private static async Task<TClient> GetLazyClientAsync<TClient>(
        AppOptions options,
        SemaphoreSlim locker,
        Func<AppOptions, Task<TClient>> factory)
    {
        await locker.WaitAsync();

        try
        {
            return await factory(options);
        }
        finally
        {
            locker.Release();
        }
    }
    
}