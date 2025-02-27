
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankPerUser
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
        AND p.Score IS NOT NULL
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.OwnerUserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.CreationDate < '2024-10-01 12:34:56' - INTERVAL 3 MONTH 
    GROUP BY 
        u.Id, u.DisplayName
    HAVING 
        SUM(p.Score) > 100
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(*) AS ActivityCount
    FROM 
        Votes v
    JOIN 
        Posts p ON v.PostId = p.Id
    WHERE 
        v.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 WEEK
    GROUP BY 
        p.Id, p.OwnerUserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    r.Title,
    r.CreationDate,
    r.Score,
    COALESCE(ac.ActivityCount, 0) AS RecentActivityCount,
    rt.TotalScore
FROM 
    Users u
JOIN 
    RankedPosts r ON u.Id = r.PostId
LEFT JOIN 
    RecentActivity ac ON r.PostId = ac.PostId
JOIN 
    TopUsers rt ON u.Id = rt.UserId
WHERE 
    r.RankPerUser = 1
    AND (u.Location IS NOT NULL OR u.WebsiteUrl IS NOT NULL)
ORDER BY 
    rt.TotalScore DESC, u.Reputation DESC
LIMIT 50;
