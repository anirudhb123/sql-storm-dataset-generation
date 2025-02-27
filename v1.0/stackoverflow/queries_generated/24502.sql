WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        UNNEST(string_to_array(p.Tags, '>')) AS t(TagName) ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.PostTypeId, p.Title, p.Score, p.CreationDate, p.ViewCount
),
PostHistoryCTE AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        ph.CreationDate,
        ph.Comment,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL '6 months'
),
FilteredHistory AS (
    SELECT 
        PostId,
        STRING_AGG(DISTINCT Comment, '; ') AS Comments,
        MAX(CreationDate) AS LastChangeDate
    FROM 
        PostHistoryCTE
    WHERE 
        HistoryRank <= 5 
    GROUP BY 
        PostId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(fh.Comments, 'No recent edits') AS RecentComments,
    COALESCE(fh.LastChangeDate, 'No changes') AS LastChange,
    rp.Tags,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Post'
        WHEN rp.Rank <= 10 THEN 'Trending'
        ELSE 'Regular'
    END AS PostRankCategory,
    (SELECT AVG(reputation) FROM Users u WHERE u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = rp.PostId)) AS AvgOwnerReputation
FROM 
    RankedPosts rp
LEFT JOIN 
    FilteredHistory fh ON rp.PostId = fh.PostId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC, rp.CreationDate DESC
OFFSET 5 ROWS -- skip the top 5 results
FETCH NEXT 10 ROWS ONLY; -- fetch the next 10 results

This SQL query accomplishes the following complex tasks:

1. **Common Table Expressions (CTEs)**: It uses two CTEs:
   - `RankedPosts`: Ranks posts based on their score and collects various metrics, alongside aggregating their tags.
   - `PostHistoryCTE`: Retrieves the history of posts over the last 6 months, focusing on recent changes.

2. **Window Functions**: The `ROW_NUMBER()` function is used in both CTEs to rank posts and filter the history of changes.

3. **Aggregations**: 
   - It calculates comment counts and combines multiple votes (upvotes/downvotes) per post in the `RankedPosts` CTE.
   - It aggregates recent comments in the `FilteredHistory` CTE.

4. **NULL Handling**: Uses `COALESCE` to handle cases where there may be no recent comments or changes.

5. **Advanced Filtering and Ranking**: The main selection filters for the top-ranked posts and categorizes them based on their rank while skipping the top 5 posts and fetching the next 10.

6. **Subqueries**: Uses a subquery to compute the average reputation of post owners directly associated with each post.

7. **String Manipulation**: Employs string functions to process tags.

8. **Bizarre SQL Semantics**: The use of `UNNEST(string_to_array(...))` is a creative way to handle tags in a relational format.

This query is complex and showcases various SQL concepts while adhering to the provided schema.
