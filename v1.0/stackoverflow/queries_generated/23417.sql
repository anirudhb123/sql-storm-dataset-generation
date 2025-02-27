WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        DisplayName,
        Reputation,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS ReputationRank,
        SUM(COALESCE(UpVotes, 0) - COALESCE(DownVotes, 0)) OVER (PARTITION BY Location) AS LocationScore,
        COUNT(CASE WHEN CreationDate < NOW() - INTERVAL '1 year' THEN 1 END) AS OlderThanOneYear
    FROM Users
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ViewCount) AS TotalViews,
        AVG(COALESCE(Score, 0)) AS AverageScore
    FROM Posts
    GROUP BY OwnerUserId
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(Name, ', ') FILTER (WHERE Class = 1) AS GoldBadges,
        STRING_AGG(Name, ', ') FILTER (WHERE Class = 2) AS SilverBadges,
        STRING_AGG(Name, ', ') FILTER (WHERE Class = 3) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
RankedUsers AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        ur.Reputation,
        ur.LocationScore,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalViews,
        ps.AverageScore,
        ub.BadgeCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY ur.Reputation DESC, ps.TotalPosts DESC) AS OverallRank
    FROM UserReputation ur
    LEFT JOIN PostStats ps ON ur.UserId = ps.OwnerUserId
    LEFT JOIN UserBadges ub ON ur.UserId = ub.UserId
)

SELECT 
    ru.DisplayName,
    ru.Reputation,
    ru.LocationScore,
    ru.TotalPosts,
    ru.TotalQuestions,
    ru.TotalAnswers,
    ru.TotalViews,
    ru.AverageScore,
    ru.BadgeCount,
    COALESCE(ru.GoldBadges, 'None') AS GoldBadges,
    COALESCE(ru.SilverBadges, 'None') AS SilverBadges,
    COALESCE(ru.BronzeBadges, 'None') AS BronzeBadges,
    ru.OverallRank,
    CASE 
        WHEN ru.Reputation > 1000 THEN 'High Reputation'
        WHEN ru.Reputation > 500 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN ru.TotalPostCount IS NULL THEN 'No Posts Yet'
        ELSE 'Active Contributor'
    END AS ActivityStatus
FROM RankedUsers ru
WHERE ru.OlderThanOneYear = 1
ORDER BY ru.OverallRank
FETCH FIRST 10 ROWS ONLY;

-- Further complexity added by examining post history types, closed posts, and post links
SELECT 
    u.DisplayName, 
    COUNT(DISTINCT ph.Id) AS HistoryEntries,
    COUNT(DISTINCT pl.RelatedPostId) AS RelatedPosts,
    COUNT(DISTINCT CASE WHEN p.ClosedDate IS NOT NULL THEN p.Id END) AS ClosedPosts
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostHistory ph ON p.Id = ph.PostId
LEFT JOIN PostLinks pl ON p.Id = pl.PostId
WHERE u.Reputation > 1500 
GROUP BY u.DisplayName
ORDER BY HistoryEntries DESC, RelatedPosts DESC
FETCH FIRST 5 ROWS ONLY;
