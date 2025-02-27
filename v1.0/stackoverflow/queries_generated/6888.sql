WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT c.Id) AS CommentsCount,
        SUM(v.BountyAmount) AS TotalBountyEarned
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        PostsCount,
        CommentsCount,
        TotalBountyEarned,
        RANK() OVER (ORDER BY SUM(PostsCount + CommentsCount) DESC) AS UserRank
    FROM UserStats
    GROUP BY UserId, DisplayName, GoldBadges, SilverBadges, BronzeBadges, PostsCount, CommentsCount, TotalBountyEarned
)
SELECT 
    UserRank,
    DisplayName,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    PostsCount,
    CommentsCount,
    TotalBountyEarned
FROM TopUsers
WHERE UserRank <= 10
ORDER BY UserRank;
