WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerName
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' 
        AND p.PostTypeId = 1
),
PostStatistics AS (
    SELECT 
        pp.OwnerName,
        COUNT(*) AS TotalPosts,
        SUM(pp.Score) AS TotalScore,
        AVG(pp.ViewCount) AS AverageViews
    FROM 
        RankedPosts pp
    WHERE 
        pp.Rank <= 3
    GROUP BY 
        pp.OwnerName
)
SELECT 
    ps.OwnerName,
    ps.TotalPosts,
    ps.TotalScore,
    ps.AverageViews,
    CASE 
        WHEN ps.TotalScore > 100 THEN 'High Score'
        WHEN ps.TotalScore BETWEEN 50 AND 100 THEN 'Medium Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    (SELECT COUNT(DISTINCT b.Id) 
     FROM Badges b 
     JOIN Users u ON b.UserId = u.Id 
     WHERE u.DisplayName = ps.OwnerName) AS BadgeCount
FROM 
    PostStatistics ps
ORDER BY 
    ps.TotalScore DESC
LIMIT 10;

SELECT 
    DISTINCT t.TagName, 
    COUNT(DISTINCT p.Id) AS PostCount
FROM 
    Tags t
LEFT JOIN 
    Posts p ON p.Tags LIKE '%' || t.TagName || '%'
WHERE 
    t.IsModeratorOnly = 0
GROUP BY 
    t.TagName
HAVING 
    COUNT(DISTINCT p.Id) > 5
ORDER BY 
    PostCount DESC
LIMIT 5;

SELECT 
    ph.UserId,
    ph.UserDisplayName,
    COUNT(*) AS EditCount,
    MAX(ph.CreationDate) AS LastEditDate
FROM 
    PostHistory ph
WHERE 
    ph.PostHistoryTypeId IN (4, 5, 6)
GROUP BY 
    ph.UserId, ph.UserDisplayName
HAVING 
    COUNT(*) > 10
ORDER BY 
    LastEditDate DESC;

WITH CloseReasons AS (
    SELECT 
        DISTINCT p.Id AS PostId,
        cr.Name AS CloseReason
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.PostHistoryTypeId = 10
)
SELECT 
    p.Title,
    COUNT(cr.CloseReason) AS CloseReasonCount,
    STRING_AGG(cr.CloseReason, ', ') AS Reasons
FROM 
    Posts p
LEFT JOIN 
    CloseReasons cr ON p.Id = cr.PostId
GROUP BY 
    p.Id, p.Title
HAVING 
    COUNT(cr.CloseReason) > 0
ORDER BY 
    CloseReasonCount DESC;
