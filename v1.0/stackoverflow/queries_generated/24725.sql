WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        P.Views,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (ORDER BY p.CreationDate DESC) AS RecentPostsRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
PopularUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(bp.Score, 0)) AS TotalScore,
        COUNT(DISTINCT bp.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        (SELECT p.Id, p.Score FROM Posts p WHERE p.Score > 10) bp ON p.Id = bp.Id
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT bp.Id) > 5
)
SELECT 
    ru.DisplayName,
    ru.TotalScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.CommentCount,
    CASE
        WHEN rp.RankByScore = 1 THEN 'Top Performer'
        WHEN rp.RankByScore <= 10 THEN 'High Scorer'
        ELSE 'Regular Contributor'
    END AS PerformanceCategory,
    CASE 
        WHEN rp.Score IS NULL THEN 'No Score Yet'
        WHEN rp.Score < 0 THEN 'Needs Improvement'
        ELSE 'Well Received'
    END AS ScoreStatus
FROM 
    RankedPosts rp
LEFT JOIN 
    PopularUsers ru ON rp.PostId IN (SELECT PostId FROM Posts WHERE OwnerUserId = ru.UserId)
WHERE 
    rp.RecentPostsRank <= 20
ORDER BY 
    ru.TotalScore DESC,
    rp.Score DESC
LIMIT 50;

