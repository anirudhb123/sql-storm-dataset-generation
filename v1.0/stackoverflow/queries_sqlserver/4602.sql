
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        DENSE_RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank,
        COUNT(c.Id) AS CommentCount,
        AVG(v.BountyAmount) AS AvgBounty,
        p.OwnerUserId
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(ISNULL(bp.Reputation, 0)) AS TotalReputation,
        ISNULL(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        ISNULL(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        ISNULL(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        (SELECT 
            Id, Reputation 
         FROM 
            Users 
         WHERE 
            LastAccessDate >= DATEADD(year, -1, '2024-10-01 12:34:56')) AS bp ON u.Id = bp.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalReputation,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    rp.PostRank,
    rp.CommentCount,
    rp.AvgBounty
FROM 
    UserStats us
JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    us.TotalReputation > 1000 AND 
    rp.PostRank <= 5
ORDER BY 
    us.TotalReputation DESC, 
    rp.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
