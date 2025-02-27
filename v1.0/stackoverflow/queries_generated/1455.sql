WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserRank,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
        AND p.Score >= 5
    GROUP BY 
        p.Id
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(b.Class) AS TotalBadgeClass,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id
),
PostAnalysis AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.CommentCount,
        us.UserId,
        us.DisplayName,
        us.TotalBadgeClass,
        r.LastEditDate,
        CASE 
            WHEN r.CommentCount > 10 THEN 'High Activity'
            ELSE 'Low Activity'
        END AS ActivityLevel
    FROM 
        RankedPosts r
    JOIN 
        UserStats us ON r.UserRank = 1
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.CreationDate,
    pa.CommentCount,
    pa.DisplayName,
    pa.TotalBadgeClass,
    pa.LastEditDate,
    pa.ActivityLevel
FROM 
    PostAnalysis pa
WHERE 
    pa.ActivityLevel = 'High Activity'
ORDER BY 
    pa.CommentCount DESC
LIMIT 10
UNION ALL
SELECT 
    p.Id,
    p.Title,
    p.CreationDate,
    COALESCE(c.CommentCount, 0) AS CommentCount,
    'Unknown User' AS DisplayName,
    0 AS TotalBadgeClass,
    p.LastEditDate,
    'No Activity' AS ActivityLevel
FROM 
    Posts p
LEFT JOIN 
    (SELECT 
        PostId, COUNT(*) AS CommentCount 
     FROM 
        Comments 
     GROUP BY 
        PostId) c ON p.Id = c.PostId
WHERE 
    p.Id NOT IN (SELECT PostId FROM PostAnalysis)
    AND p.Score < 5;
