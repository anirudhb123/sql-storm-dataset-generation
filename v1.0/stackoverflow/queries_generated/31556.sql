WITH RecursiveCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions

    UNION ALL

    SELECT 
        a.Id AS PostId,
        a.Title,
        a.CreationDate,
        a.Score,
        a.ViewCount,
        a.AcceptedAnswerId,
        r.Level + 1
    FROM 
        Posts a
    INNER JOIN 
        Posts q ON a.ParentId = q.Id
    INNER JOIN 
        RecursiveCTE r ON q.Id = r.PostId
)

SELECT 
    u.DisplayName AS User,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.ViewCount,
    COALESCE(COUNT(c.Id), 0) AS CommentCount,
    COALESCE(MAX(b.Date), 'No Badge') AS LatestBadgeDate,
    DENSE_RANK() OVER (PARTITION BY r.PostId ORDER BY r.Score DESC) AS ScoreRank
FROM 
    RecursiveCTE r
LEFT JOIN 
    Users u ON r.AcceptedAnswerId = u.Id
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1 -- Gold badges
GROUP BY 
    u.DisplayName, r.PostId, r.Title, r.CreationDate, r.Score, r.ViewCount
HAVING 
    COUNT(c.Id) > 0 OR MAX(b.Date) IS NOT NULL
ORDER BY 
    r.ViewCount DESC,
    ScoreRank ASC;
