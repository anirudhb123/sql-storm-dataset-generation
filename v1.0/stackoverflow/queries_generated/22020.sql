WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RecentRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    u.DisplayName,
    us.BadgeCount,
    us.TotalViews,
    us.AvgPostScore,
    p.Title,
    p.Score,
    p.ViewCount,
    COALESCE(ph.Comment, 'No comments') AS LastComment,
    CASE 
        WHEN ph.CreationDate IS NOT NULL THEN
            'Last activity was on: ' || TO_CHAR(ph.CreationDate, 'YYYY-MM-DD HH24:MI:SS')
        ELSE 
            'No activity'
    END AS ActivityMessage
FROM 
    Users u
JOIN 
    UserStats us ON u.Id = us.UserId
LEFT JOIN 
    RankedPosts p ON us.UserId = p.PostId
LEFT JOIN 
    (SELECT 
        c.PostId,
        MAX(c.CreationDate) AS CreationDate,
        STRING_AGG(c.Text, ' | ') AS Comment
     FROM 
        Comments c
     GROUP BY 
        c.PostId) ph ON p.PostId = ph.PostId
WHERE 
    us.AvgPostScore > 5 OR us.BadgeCount > 3
ORDER BY 
    us.TotalViews DESC, us.AvgPostScore DESC NULLS LAST
LIMIT 50;
