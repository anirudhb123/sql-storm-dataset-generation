WITH RecursivePostChain AS (
    -- CTE to find all posts linked through PostLinks
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        1 AS Depth
    FROM 
        PostLinks pl
    UNION ALL
    SELECT 
        pl.PostId,
        pl.RelatedPostId,
        rpc.Depth + 1
    FROM 
        PostLinks pl
    INNER JOIN 
        RecursivePostChain rpc ON pl.PostId = rpc.RelatedPostId
),
PostStatistics AS (
    -- Get overall post statistics including vote counts and comments
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty,
        MAX(p.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistoryAggregates AS (
    -- Aggregate post history to find recent close and reopen actions
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS LastReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    ps.PostId,
    ps.CommentCount,
    ps.UpVoteCount,
    ps.DownVoteCount,
    ps.TotalBounty,
    COALESCE(ph.LastClosedDate, 'Never') AS LastClosed,
    COALESCE(ph.LastReopenedDate, 'Never') AS LastReopened,
    COUNT(rpc.RelatedPostId) AS RelatedPostsCount
FROM 
    PostStatistics ps
LEFT JOIN 
    PostHistoryAggregates ph ON ps.PostId = ph.PostId
LEFT JOIN 
    RecursivePostChain rpc ON ps.PostId = rpc.PostId
WHERE 
    ps.CommentCount > 0
    OR ps.UpVoteCount > ps.DownVoteCount
GROUP BY 
    ps.PostId, ps.CommentCount, ps.UpVoteCount, ps.DownVoteCount, ps.TotalBounty, ph.LastClosedDate, ph.LastReopenedDate
ORDER BY 
    ps.TotalBounty DESC, ps.CommentCount DESC, LastActivityDate DESC;
