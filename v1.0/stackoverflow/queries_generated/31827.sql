WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        CreationDate,
        LastActivityDate,
        1 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.CreationDate,
        p.LastActivityDate,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy php ON p.ParentId = php.Id
),
AggregatedVotes AS (
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
),
ClosedPostCount AS (
    SELECT 
        PostId,
        COUNT(*) AS CloseCount
    FROM PostHistory
    WHERE PostHistoryTypeId = 10
    GROUP BY PostId
),
DetailedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.LastActivityDate,
        COALESCE(av.UpVoteCount, 0) AS UpVotes,
        COALESCE(av.DownVoteCount, 0) AS DownVotes,
        COALESCE(cpc.CloseCount, 0) AS CloseCount,
        ROW_NUMBER() OVER (PARTITION BY php.Level ORDER BY p.LastActivityDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN AggregatedVotes av ON p.Id = av.PostId
    LEFT JOIN ClosedPostCount cpc ON p.Id = cpc.PostId
    LEFT JOIN RecursivePostHierarchy php ON p.Id = php.Id
)
SELECT 
    dp.Title,
    dp.CreationDate,
    dp.LastActivityDate,
    dp.UpVotes,
    dp.DownVotes,
    dp.CloseCount,
    CASE 
        WHEN dp.CloseCount > 0 THEN 'Closed'
        ELSE 'Active'
    END AS Status,
    CASE 
        WHEN dp.UpVotes > dp.DownVotes THEN 'Positive'
        WHEN dp.UpVotes < dp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM DetailedPosts dp
WHERE dp.PostRank <= 10
ORDER BY dp.CreationDate DESC;

This SQL query incorporates various advanced constructs:

1. **Recursive CTE**: `RecursivePostHierarchy` gathers all the posts and their hierarchical relationships.
2. **Aggregated Calculations**: `AggregatedVotes` computes the upvotes and downvotes for each post.
3. **NULL logic with COALESCE**: Handles cases where there may be no votes or close histories.
4. **Window Functions**: Utilizes `ROW_NUMBER()` to rank posts within their hierarchy levels.
5. **CASE Expressions**: Creates sentiment status based on vote counts and post status based on closings.
6. **Outer Joins**: Ensures that all posts are returned even if there are no votes or closings. 
7. **Complex Predicate Logic**: Uses conditions to classify posts based on their vote sentiments.

This comprehensive query acts as a benchmark for performance, challenging the system with multiple joins, calculations, and aggregations under a cohesive structure.
