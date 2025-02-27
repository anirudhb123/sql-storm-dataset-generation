WITH RecursivePostCTE AS (
    -- Recursive CTE to find all related posts through links
    SELECT pl.PostId, pl.RelatedPostId, 1 AS Depth
    FROM PostLinks pl
    WHERE pl.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId IS NOT NULL)
    
    UNION ALL
    
    SELECT pl.PostId, pl.RelatedPostId, rpc.Depth + 1
    FROM PostLinks pl
    JOIN RecursivePostCTE rpc ON pl.PostId = rpc.RelatedPostId
),
UserVoteCounts AS (
    -- CTE to count votes per user along with their reputation
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.Reputation
),
PostMetrics AS (
    -- CTE to get various metrics for posts with combined user and post data
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(SUM(CASE WHEN c.PostId IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS VoteCount,
        COALESCE(rp.Depth, 0) AS RelatedDepth
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN RecursivePostCTE rp ON p.Id = rp.PostId
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, rp.Depth
)
SELECT 
    p.Title,
    p.CreationDate,
    p.Score,
    p.ViewCount,
    pm.CommentCount,
    pm.VoteCount,
    pm.RelatedDepth,
    u.Reputation,
    u.UpvoteCount,
    u.DownvoteCount
FROM PostMetrics pm
JOIN Users u ON pm.PostId IN (SELECT postId FROM Posts WHERE OwnerUserId = u.Id)
LEFT JOIN (SELECT DISTINCT RelatedPostId FROM RecursivePostCTE) rh ON pm.PostId = rh.RelatedPostId
WHERE pm.Score > 10
ORDER BY pm.Score DESC, pm.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
