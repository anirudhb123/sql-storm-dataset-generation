
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        @row_num := IF(@prev_user_id = p.OwnerUserId, @row_num + 1, 1) AS Rank,
        @prev_user_id := p.OwnerUserId
    FROM 
        Posts p
    CROSS JOIN (SELECT @row_num := 0, @prev_user_id := NULL) r
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.Score DESC
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) 
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.DisplayName,
    us.PostCount,
    us.TotalScore,
    us.TotalBounties,
    rp.Title,
    rp.ViewCount,
    rp.Score,
    CASE 
        WHEN rp.Rank = 1 THEN 'Best Post'
        ELSE NULL 
    END AS IsBestPost
FROM 
    UserStatistics us
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.PostId
WHERE 
    us.PostCount > 5 
    AND (us.TotalScore IS NOT NULL OR us.TotalBounties > 0)
ORDER BY 
    us.TotalScore DESC, us.PostCount DESC
LIMIT 100;
