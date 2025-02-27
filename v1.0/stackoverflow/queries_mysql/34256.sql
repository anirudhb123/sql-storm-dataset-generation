
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
),

UserPostCount AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),

TopPostScores AS (
    SELECT
        PostId,
        SUM(CASE WHEN vt.VoteTypeId = 2 THEN 1
                 WHEN vt.VoteTypeId = 3 THEN -1
                 ELSE 0 END) AS Score,
        @rownum := IF(@prevPostTypeId = p.PostTypeId, @rownum + 1, 1) AS Rank,
        @prevPostTypeId := p.PostTypeId
    FROM 
        Posts p
    LEFT JOIN 
        Votes vt ON p.Id = vt.PostId
    CROSS JOIN (SELECT @rownum := 0, @prevPostTypeId := '') r
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY 
        PostId, p.PostTypeId
)

SELECT 
    ph.PostId,
    ph.Title,
    ph.Level,
    COALESCE(upc.PostCount, 0) AS UserPostCount,
    ps.Score,
    ps.Rank
FROM 
    PostHierarchy ph
LEFT JOIN 
    UserPostCount upc ON upc.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = ph.PostId)
LEFT JOIN 
    TopPostScores ps ON ps.PostId = ph.PostId
WHERE 
    ph.Level <= 2
ORDER BY 
    ph.Level, ps.Score DESC;
