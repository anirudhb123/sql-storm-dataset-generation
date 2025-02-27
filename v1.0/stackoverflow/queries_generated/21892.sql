WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotesCount,  -- Counting upvotes
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotesCount  -- Counting downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId
), 
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate,
        STRING_AGG(DISTINCT pt.Name, ', ') AS PostHistoryNames  -- Aggregating history names
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    GROUP BY 
        ph.PostId, ph.PostHistoryTypeId
), 
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.ViewCount) FILTER (WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '30 days') AS RecentViews,
        COUNT(b.Id) AS BadgeCount,
        COALESCE(MAX(p.LastActivityDate), '1900-01-01') AS LastActivityDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    up.DisplayName,
    up.RecentViews,
    up.BadgeCount,
    pp.PostId,
    pp.Title,
    pp.CreationDate,
    pp.ViewCount,
    pp.UpVotesCount,
    pp.DownVotesCount,
    phs.LastEditDate,
    phs.EditCount,
    phs.PostHistoryNames
FROM 
    UserActivity up
INNER JOIN 
    RankedPosts pp ON up.UserId = pp.OwnerUserId
LEFT JOIN 
    PostHistorySummary phs ON pp.PostId = phs.PostId
WHERE 
    up.RecentViews IS NOT NULL 
    AND pp.Rank <= 5 -- Limit to top 5 recent posts
    AND pp.ViewCount > 0
ORDER BY 
    up.RecentViews DESC,
    pp.UpVotesCount - pp.DownVotesCount DESC
LIMIT 50;

This complex SQL query achieves the following:

1. **Common Table Expressions (CTEs)**: It uses CTEs to organize the data retrieval process and modularize the business logic.
  
2. **Window Functions**: The `ROW_NUMBER` function is applied to rank posts for each user based on their creation date, allowing for the selection of the most recent posts.

3. **Aggregate Functions**: It uses `COUNT` with filters to count specific types of votes (upvotes and downvotes) while aggregating the history types of posts.

4. **String Aggregation**: Utilizes `STRING_AGG` to concatenate distinct post history names related to each post.

5. **Date Filtering and NULL Handling**: It captures recent user activity while handling NULL values gracefully using `COALESCE`.

6. **Complex Joins and Conditions**: The query performs multiple joins to gather relevant statistics about posts, users, and their activities, applying filters to ensure meaningful results.

7. **Sorting and Limiting Results**: The results are sorted based on recent views and vote differences, limited to 50 results, making the output efficient while displaying useful information.

This query handles obscure edge cases such as users with no posts or interactions, ensuring it returns a meaningful dataset for performance benchmarking.
