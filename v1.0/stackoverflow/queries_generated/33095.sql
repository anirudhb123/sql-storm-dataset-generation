WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    WHERE 
        p.PostTypeId = 1  -- Questions only
    GROUP BY 
        p.Id, p.Title, p.ParentId, p.Score

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1 AS Level,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- BountyStart
    GROUP BY 
        p.Id, p.Title, p.ParentId, ph.Level, p.Score
),

PostStats AS (
    SELECT 
        ph.PostId,
        ph.Title,
        ph.Level,
        ph.Score,
        ph.CommentCount,
        ph.TotalBounty,
        COUNT(DISTINCT bh.UserId) AS BadgeCount,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        PostHierarchy ph
    LEFT JOIN 
        Badges bh ON bh.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = ph.PostId)
    LEFT JOIN 
        Users u ON u.Id IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Id = ph.PostId)
    GROUP BY 
        ph.PostId, ph.Title, ph.Level, ph.Score, ph.CommentCount, ph.TotalBounty
)

SELECT 
    ps.PostId,
    ps.Title,
    ps.Level,
    ps.Score,
    ps.CommentCount,
    ps.TotalBounty,
    ps.BadgeCount,
    ps.AvgReputation,
    CASE 
        WHEN ps.Score > 10 THEN 'High Score'
        WHEN ps.Score BETWEEN 5 AND 10 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory
FROM 
    PostStats ps
ORDER BY 
    ps.Score DESC, ps.CommentCount DESC
LIMIT 100;

