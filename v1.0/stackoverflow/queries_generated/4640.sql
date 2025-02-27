WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostCounts AS (
    SELECT 
        OwnerUserId,
        COUNT(Id) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers
    FROM Posts
    GROUP BY OwnerUserId
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        ps.TotalPosts,
        ps.Questions,
        ps.Answers,
        RANK() OVER (ORDER BY us.Reputation DESC) AS UserRank
    FROM UserStats us
    INNER JOIN PostCounts ps ON us.UserId = ps.OwnerUserId
    WHERE us.Reputation > 1000 -- filter for users with reputation > 1000
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.UserRank,
    COALESCE(SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END), 0) AS PopularPostsCount,
    STRING_AGG(DISTINCT CASE WHEN t.TagName IS NOT NULL THEN t.TagName END, ', ') AS TagsUsed
FROM TopUsers tu
LEFT JOIN Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN STRING_TO_ARRAY(p.Tags, ',') AS t ON t.TagName IS NOT NULL
GROUP BY tu.DisplayName, tu.TotalPosts, tu.Questions, tu.Answers, tu.UserRank
HAVING COUNT(p.Id) > 10 -- only users with more than 10 posts
ORDER BY tu.UserRank;
