WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COALESCE(p.AcceptedAnswerId, 0) AS AcceptedAnswerId,
        p.Score,
        p.ViewCount,
        pm.Name AS PostTypeName,
        (
            SELECT COUNT(*)
            FROM Comments c
            WHERE c.PostId = p.Id
        ) AS CommentCount
    FROM 
        Posts p
    JOIN 
        PostTypes pm ON p.PostTypeId = pm.Id
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
UserPostComments AS (
    SELECT 
        up.UserId,
        COUNT(*) AS UserCommentCount
    FROM 
        Comments c
    LEFT JOIN 
        Posts p ON c.PostId = p.Id
    LEFT JOIN 
        Users up ON p.OwnerUserId = up.Id
    GROUP BY 
        up.UserId
)
SELECT 
    us.DisplayName,
    us.TotalPosts,
    us.TotalScore,
    us.GoldBadges,
    us.SilverBadges,
    us.BronzeBadges,
    COALESCE(upc.UserCommentCount, 0) AS UserComments,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.RecentPostRank,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL AND rp.AcceptedAnswerId != 0 THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AcceptanceStatus
FROM 
    UserStatistics us
LEFT JOIN 
    UserPostComments upc ON us.UserId = upc.UserId
LEFT JOIN 
    RankedPosts rp ON us.UserId = rp.OwnerUserId
WHERE 
    (us.TotalPosts > 10 OR us.TotalScore > 100)
    AND rp.RecentPostRank <= 5
    AND rp.CommentCount > 5
ORDER BY 
    us.TotalScore DESC, 
    rp.CreationDate DESC
LIMIT 100;
