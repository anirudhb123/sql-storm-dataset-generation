WITH RecursivePostHierarchy AS (
    -- CTE to create a hierarchy of posts and their corresponding answers
    SELECT 
        Id AS PostId,
        Title,
        Score,
        ParentId,
        CreationDate,
        1 AS Level
    FROM Posts
    WHERE ParentId IS NULL  -- Get top-level posts (Questions)
    
    UNION ALL
    
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy ph ON p.ParentId = ph.PostId
),

PostVoteSummary AS (
    -- CTE to summarize votes per post
    SELECT 
        PostId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM Votes
    GROUP BY PostId
),

RecentPostEdits AS (
    -- CTE to get the most recent edit for each post
    SELECT 
        PostId,
        PostHistoryTypeId,
        MAX(CreationDate) AS LastEditDate
    FROM PostHistory
    WHERE PostHistoryTypeId IN (4, 5, 6)  -- Edits of Title, Body, Tags
    GROUP BY PostId, PostHistoryTypeId
),

TagsSummary AS (
    -- CTE to summarize the tags associated with each post
    SELECT 
        p.Id AS PostId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN LATERAL (
        SELECT unnest(string_to_array(Tags, '>,<')) AS TagName
        FROM Posts
        WHERE Id = p.Id 
    ) t ON true
    GROUP BY p.Id
)

-- Main query combining all the above CTEs
SELECT 
    p.PostId,
    p.Title,
    ph.Level,
    COALESCE(v.TotalUpvotes, 0) AS TotalUpvotes,
    COALESCE(v.TotalDownvotes, 0) AS TotalDownvotes,
    COALESCE(STRING_AGG(DISTINCT ts.Tags, '; '), 'No Tags') AS Tags,
    COALESCE(
        MAX(e.LastEditDate), 
        'No Edits'::timestamp
    ) AS LastEditDate
FROM RecursivePostHierarchy p
LEFT JOIN PostVoteSummary v ON p.PostId = v.PostId
LEFT JOIN RecentPostEdits e ON p.PostId = e.PostId
LEFT JOIN TagsSummary ts ON p.PostId = ts.PostId
GROUP BY p.PostId, p.Title, ph.Level
ORDER BY p.PostId;
