
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(IFNULL(p.Score, 0)) AS TotalScore,
        SUM(IFNULL(b.Class, 0)) AS TotalBadges,
        AVG(IFNULL(v.VoteTypeId, 0)) AS AverageVoteType
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, 
        u.DisplayName
),
PostHistoryInfo AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    us.TotalBadges,
    us.AverageVoteType,
    pp.Title,
    pp.UserPostRank,
    IFNULL(phi.EditCount, 0) AS EditCount,
    IFNULL(phi.CloseCount, 0) AS CloseCount,
    phi.LastEditDate
FROM 
    UserStats us
JOIN 
    RankedPosts pp ON us.UserId = pp.OwnerUserId
LEFT JOIN 
    PostHistoryInfo phi ON pp.PostId = phi.PostId
WHERE 
    us.TotalPosts > 5 
    AND us.TotalScore > 50
ORDER BY 
    us.TotalScore DESC, 
    pp.UserPostRank
LIMIT 10;
