WITH RecursiveUserTree AS (
    SELECT Id, Reputation, CreationDate, DisplayName, 
           CAST(DisplayName AS VARCHAR(1000)) AS FullPath
    FROM Users
    WHERE Id IS NOT NULL  -- Base case; only include valid users
    UNION ALL
    SELECT u.Id, u.Reputation, u.CreationDate, u.DisplayName,
           CAST(CONCAT(r.FullPath, ' -> ', u.DisplayName) AS VARCHAR(1000)) AS FullPath
    FROM Users u
    JOIN RecursiveUserTree r ON u.Id = r.Id + 1  -- Recursive case, simulate user hierarchy
),
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    GROUP BY p.OwnerUserId
),
UserPostStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.AvgScore,
        ps.LastPostDate,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
    LEFT JOIN PostStatistics ps ON u.Id = ps.OwnerUserId
),
TopUsers AS (
    SELECT *
    FROM UserPostStatistics
    WHERE ReputationRank <= 10  -- Top 10 users based on reputation
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.AvgScore,
    u.LastPostDate,
    COALESCE(ub.TotalBadges, 0) AS TotalBadges,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    CASE 
        WHEN u.LastPostDate < NOW() - INTERVAL '1 year' THEN 'Inactive'
        ELSE 'Active'
    END AS ActivityStatus,
    CASE 
        WHEN u.Reputation > 1000 THEN 'High Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory
FROM TopUsers u
LEFT JOIN UserBadges ub ON u.UserId = ub.UserId
ORDER BY u.Reputation DESC;
