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
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),

PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.AuthorUserId,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.OwnerUserId
),

HighScoringPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ROW_NUMBER() OVER (ORDER BY ps.UpVoteCount - ps.DownVoteCount DESC) AS rn
    FROM 
        PostStatistics ps
    WHERE 
        ps.UpVoteCount > 0
)

SELECT 
    h.Id AS PostId,
    h.Title AS PostTitle,
    ph.Depth AS HierarchyDepth,
    hs.CommentCount,
    hs.UpVoteCount,
    hs.DownVoteCount,
    CASE 
        WHEN hs.CommentCount IS NULL THEN 'No Comments'
        ELSE 'Has Comments'
    END AS Comment_Status,
    hs.TotalViews
FROM 
    RecursivePostHierarchy ph
JOIN 
    Posts h ON ph.Id = h.Id
LEFT JOIN 
    PostStatistics hs ON h.Id = hs.PostId
WHERE 
    ph.Depth < 3
ORDER BY 
    ph.Depth, hs.UpVoteCount DESC
FETCH FIRST 100 ROWS ONLY;
