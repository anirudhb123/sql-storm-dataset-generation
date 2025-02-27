
WITH ranked_posts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS Rank,
        @prev_owner_user_id := p.OwnerUserId,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS params
    WHERE 
        p.CreationDate >= DATE_SUB(CURDATE(), INTERVAL 1 YEAR) AND
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
user_stats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName
),
top_users AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.GoldBadges,
        us.SilverBadges,
        us.BronzeBadges,
        us.TotalViews,
        @user_rank := @user_rank + 1 AS UserRank
    FROM 
        user_stats us
    CROSS JOIN (SELECT @user_rank := 0) AS ranks
    ORDER BY 
        us.TotalViews DESC
)
SELECT 
    up.DisplayName,
    rp.Title AS TopPostTitle,
    rp.Score AS TopPostScore,
    rp.ViewCount AS TopPostViews,
    up.GoldBadges,
    up.SilverBadges,
    up.BronzeBadges,
    up.TotalViews
FROM 
    ranked_posts rp
JOIN 
    top_users up ON rp.PostId = (SELECT 
                                       TopPostId 
                                   FROM (
                                       SELECT 
                                           p.Id AS TopPostId, 
                                           @post_rank := IF(@prev_owner_user_id2 = p.OwnerUserId, @post_rank + 1, 1) AS PostRank,
                                           @prev_owner_user_id2 := p.OwnerUserId
                                       FROM 
                                           Posts p 
                                       CROSS JOIN (SELECT @post_rank := 0, @prev_owner_user_id2 := NULL) AS params2
                                       WHERE 
                                           p.OwnerUserId IS NOT NULL
                                   ) AS ranked 
                                   WHERE 
                                       ranked.PostRank = 1 AND ranked.TopPostId = rp.PostId)
WHERE 
    up.UserRank <= 10
ORDER BY 
    up.TotalViews DESC;
