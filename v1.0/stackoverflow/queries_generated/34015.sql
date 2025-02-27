WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Depth
    FROM 
        Posts 
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostStats AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COALESCE(MAX(b.Class), 0) AS MaxBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON p.OwnerUserId = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS ClosureCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (24, 25) THEN 1 END) AS LabelChangeCount
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    COALESCE(psc.ClosureCount, 0) AS ClosureCount,
    COALESCE(psc.ReopenCount, 0) AS ReopenCount,
    ps.MaxBadgeClass,
    Row_Number() OVER (PARTITION BY r.Depth ORDER BY ps.CommentCount DESC) AS RankPerDepth
FROM 
    Posts p
JOIN 
    PostStats ps ON p.Id = ps.Id
LEFT JOIN 
    PostHistorySummary psc ON p.Id = psc.PostId
JOIN 
    RecursivePostHierarchy r ON p.Id = r.Id OR p.ParentId = r.Id
WHERE 
    (ps.UpVotes - ps.DownVotes) > 5 
    AND (ps.CommentCount > 0 OR ps.MaxBadgeClass > 1)
ORDER BY 
    ps.UpVotes DESC, ps.CommentCount DESC;
