WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(TAG_COUNT.Count, 0) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS Count
        FROM 
            Tags
        GROUP BY 
            PostId
    ) TAG_COUNT ON p.Id = TAG_COUNT.PostId
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate AS ClosedDate,
        p.Title,
        pt.Name AS PostTypeName,
        COUNT(ph.Id) AS HistoryCount
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    JOIN 
        PostHistoryTypes pt ON ph.PostHistoryTypeId = pt.Id
    WHERE 
        pt.Name LIKE '%Closed%'
    GROUP BY 
        ph.PostId, ph.CreationDate, p.Title, pt.Name
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.CreationDate > NOW() - INTERVAL '1 year' THEN 1 ELSE 0 END) AS RecentPosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
)
SELECT 
    ru.PostId,
    ru.Title,
    ru.CreationDate,
    ru.Score,
    cp.ClosedDate,
    cp.HistoryCount AS CloseHistoryCount,
    au.UserId,
    au.DisplayName,
    au.TotalPosts,
    au.RecentPosts,
    CASE 
        WHEN ru.TagCount > 5 THEN 'High Tag Usage'
        WHEN ru.TagCount BETWEEN 3 AND 5 THEN 'Moderate Tag Usage'
        ELSE 'Low Tag Usage'
    END AS TagUsage,
    CASE 
        WHEN cp.ClosedDate IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    RankedPosts ru
LEFT JOIN 
    ClosedPosts cp ON ru.PostId = cp.PostId
INNER JOIN 
    ActiveUsers au ON ru.PostId IN (
        SELECT 
            p.Id 
        FROM 
            Posts p 
        WHERE 
            p.OwnerUserId = au.UserId
    )
WHERE 
    ru.RankScore <= 5
ORDER BY 
    ru.Score DESC, 
    ru.PostId;
