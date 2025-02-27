WITH RankedUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        CreationDate,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        COUNT(PostId) AS PostCount
    FROM Users
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY Users.Id
), 
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
), 
PostsSummary AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        SUM(CASE WHEN p.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts,
        COUNT(DISTINCT p.Tags) AS DistinctTags
    FROM Posts p
    GROUP BY p.OwnerUserId
), 
TopUsers AS (
    SELECT 
        ru.Id AS UserId, 
        ru.DisplayName,
        ru.Reputation,
        pb.TotalPosts,
        pb.TotalScore,
        pb.AvgViews,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM RankedUsers ru
    JOIN PostsSummary pb ON ru.Id = pb.OwnerUserId
    LEFT JOIN UserBadges ub ON ru.Id = ub.UserId
    WHERE ru.ReputationRank <= 10
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalScore,
    tu.AvgViews,
    COALESCE(tu.GoldBadges, 0) AS GoldBadges,
    COALESCE(tu.SilverBadges, 0) AS SilverBadges,
    COALESCE(tu.BronzeBadges, 0) AS BronzeBadges
FROM TopUsers tu
ORDER BY tu.Reputation DESC;
