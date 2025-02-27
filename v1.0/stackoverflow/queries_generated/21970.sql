WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
        AND p.Score IS NOT NULL
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE 
            WHEN b.Class = 1 THEN 3 
            WHEN b.Class = 2 THEN 2 
            WHEN b.Class = 3 THEN 1 
            ELSE 0 
        END) AS BadgePoints
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        STRING_AGG(DISTINCT ctr.Name, ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes ctr ON ctr.Id::text = ph.Comment
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)
    GROUP BY 
        ph.PostId, ph.CreationDate
)
SELECT 
    p.Title,
    p.ViewCount,
    r.Reputation,
    COALESCE(cl.CloseReasons, 'Not Closed') AS CloseStatus,
    COALESCE(u.BadgePoints, 0) AS TotalBadgePoints,
    p.CreationDate,
    p.Score,
    CASE 
        WHEN p.Score = 0 THEN 'No Score Yet'
        WHEN p.Score < 10 THEN 'Low Score'
        WHEN p.Score BETWEEN 10 AND 50 THEN 'Moderate Score'
        ELSE 'High Score'
    END AS ScoreCategory
FROM 
    RankedPosts p
LEFT JOIN 
    UserReputation u ON p.OwnerUserId = u.UserId
LEFT JOIN 
    ClosedPosts cl ON p.Id = cl.PostId
WHERE 
    p.PostRank = 1
ORDER BY 
    p.Score DESC NULLS LAST,
    p.CreationDate DESC
LIMIT 50;

WITH RECURSIVE PostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.PostId
)
SELECT 
    DISTINCT ph.PostId,
    ph.Title,
    ph.Level,
    COUNT(DISTINCT c.Id) AS CommentCount,
    MAX(ph.Level) OVER (PARTITION BY ph.PostId) AS MaxLevel
FROM 
    PostHierarchy ph
LEFT JOIN 
    Comments c ON ph.PostId = c.PostId
GROUP BY 
    ph.PostId, ph.Title, ph.Level
HAVING 
    MAX(ph.Level) > 1
ORDER BY 
    MaxLevel DESC, CommentCount DESC;

SELECT 
    p.Id,
    p.Title,
    p.Body,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) THEN 'Upvoted'
        WHEN EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) THEN 'Downvoted'
        ELSE 'Unvoted'
    END AS VoteStatus,
    COALESCE(ROUND((SELECT AVG(VoteTypeId) FROM Votes WHERE PostId = p.Id), 2), 'No Votes') AS AverageVoteScore
FROM 
    Posts p
WHERE 
    p.Body LIKE '%SQL%'
    AND (p.Body IS NOT NULL OR p.ViewCount > 100)
ORDER BY 
    CAST(ROUND((SELECT AVG(VoteTypeId) FROM Votes WHERE PostId = p.Id), 2) AS NUMERIC) DESC;
