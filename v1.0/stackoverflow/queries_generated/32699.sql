WITH RecursivePostHierarchy AS (
    -- CTE to fetch the hierarchy of posts, assuming Posts can have parents
    SELECT 
        Id,
        Title,
        ParentId,
        Score,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        p.Score,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostMetrics AS (
    -- Calculate metrics for each post, including average score and total votes
    SELECT 
        p.Id AS PostId,
        p.Title,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(AVG(p.Score), 0) AS AverageScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
),
PostHistoryDetails AS (
    -- Fetch post history details with close reason, if applicable
    SELECT 
        ph.PostId,
        ph.UserDisplayName,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        CASE 
            WHEN ph.PostHistoryTypeId = 10 THEN ch.Name
            ELSE NULL 
        END AS CloseReason
    FROM 
        PostHistory ph
    LEFT JOIN 
        CloseReasonTypes ch ON ph.Comment::int = ch.Id
),
FinalMetrics AS (
    -- Combine posts with their metrics and history details
    SELECT 
        pm.PostId,
        pm.Title,
        pm.Upvotes,
        pm.Downvotes,
        pm.AverageScore,
        pm.CommentCount,
        COALESCE(ph.UserDisplayName, 'No Closure') AS LastUser,
        COALESCE(ph.CloseReason, 'N/A') AS LastCloseReason,
        ph.CreationDate AS LastActivityDate
    FROM 
        PostMetrics pm
    LEFT JOIN 
        PostHistoryDetails ph ON pm.PostId = ph.PostId
)
-- Finally, we will fetch data from our final metrics
SELECT 
    f.PostId,
    f.Title,
    f.Upvotes,
    f.Downvotes,
    f.AverageScore,
    f.CommentCount,
    f.LastUser,
    f.LastCloseReason,
    f.LastActivityDate
FROM 
    FinalMetrics f
WHERE 
    f.AverageScore > 0
ORDER BY 
    f.AverageScore DESC, 
    f.Upvotes DESC
LIMIT 100;

