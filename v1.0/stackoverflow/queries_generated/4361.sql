WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.Tags,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(a.AnswerCount, 0) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount 
         FROM Comments 
         GROUP BY PostId) c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT ParentId AS PostId, COUNT(*) AS AnswerCount 
         FROM Posts 
         WHERE PostTypeId = 2 
         GROUP BY ParentId) a ON p.Id = a.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class * 10) AS TotalBadgePoints
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        SUM(p.Score) > 100
)
SELECT 
    pu.DisplayName,
    pu.Reputation,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.AnswerCount,
    pu.TotalScore,
    pu.TotalBadgePoints
FROM 
    TopUsers pu
JOIN 
    RankedPosts rp ON pu.Id = rp.OwnerUserId
WHERE 
    rp.Rank <= 5
ORDER BY 
    pu.TotalBadgePoints DESC,
    rp.Score DESC
LIMIT 10;

-- Additional complex subquery for tracking post history changes
SELECT 
    p.Id AS PostId,
    MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
    MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate,
    COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS ClosureChanges
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    p.Id
HAVING 
    ClosureChanges > 0
ORDER BY 
    p.Id DESC;
