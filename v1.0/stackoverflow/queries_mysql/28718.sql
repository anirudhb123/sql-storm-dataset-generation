
WITH UserBadges AS (
    SELECT 
        u.Id AS UserID,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(p.ViewCount) AS TotalViews
    FROM Posts p
    GROUP BY p.OwnerUserId
),
RankedUsers AS (
    SELECT 
        u.DisplayName,
        ub.BadgeCount,
        pa.TotalPosts,
        pa.Questions,
        pa.Answers,
        pa.TotalViews,
        @postRank := IF(@prevPosts = pa.TotalPosts, @postRank, @postRank + 1) AS PostRank,
        @badgeRank := IF(@prevBadges = ub.BadgeCount, @badgeRank, @badgeRank + 1) AS BadgeRank,
        @prevPosts := pa.TotalPosts,
        @prevBadges := ub.BadgeCount
    FROM UserBadges ub
    JOIN PostActivity pa ON ub.UserID = pa.OwnerUserId
    JOIN Users u ON ub.UserID = u.Id,
    (SELECT @postRank := 0, @badgeRank := 0, @prevPosts := NULL, @prevBadges := NULL) AS vars
)
SELECT 
    DisplayName,
    BadgeCount,
    TotalPosts,
    Questions,
    Answers,
    TotalViews,
    PostRank,
    BadgeRank,
    CASE 
        WHEN PostRank <= 10 AND BadgeRank <= 10 THEN 'Top Contributor'
        WHEN PostRank <= 10 THEN 'Top Poster'
        WHEN BadgeRank <= 10 THEN 'Top Badges'
        ELSE 'Regular Contributor'
    END AS ContributorCategory
FROM RankedUsers
WHERE TotalPosts > 0
  AND BadgeCount > 0
ORDER BY PostRank, BadgeRank;
