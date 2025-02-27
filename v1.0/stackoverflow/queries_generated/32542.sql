WITH RecursivePosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        0 AS Depth
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Starting with questions

    UNION ALL

    SELECT 
        a.Id,
        a.Title,
        a.PostTypeId,
        a.AcceptedAnswerId,
        a.CreationDate,
        a.OwnerUserId,
        a.Score,
        rp.Depth + 1
    FROM 
        Posts a
    INNER JOIN 
        RecursivePosts rp ON a.ParentId = rp.Id
    WHERE 
        a.PostTypeId = 2  -- Only include answers
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM 
        Users u
    JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 0
),
PostsStats AS (
    SELECT 
        rp.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN rp.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN rp.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        MAX(COALESCE(rp.AcceptedAnswerId, 0)) AS MaxAcceptedAnswerId
    FROM 
        RecursivePosts rp
    GROUP BY 
        rp.OwnerUserId
)
SELECT 
    tu.DisplayName,
    tu.Rank,
    ps.TotalPosts,
    ps.PositivePosts,
    ps.NegativePosts,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges
FROM 
    TopUsers tu
LEFT JOIN 
    PostsStats ps ON tu.Id = ps.OwnerUserId
LEFT JOIN 
    UserBadges ub ON tu.Id = ub.UserId
WHERE 
    tu.Rank <= 10  -- Get only the top 10 users
ORDER BY 
    tu.Rank;
