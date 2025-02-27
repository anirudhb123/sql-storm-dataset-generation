
WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName,
        COUNT(b.Id) AS GoldBadgeCount,
        COUNT(b.Id) AS SilverBadgeCount,
        COUNT(b.Id) AS BronzeBadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
), 
PostStats AS (
    SELECT 
        p.OwnerUserId, 
        COUNT(p.Id) AS TotalPosts, 
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(IFNULL(p.Score, 0)) AS AvgScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ActiveUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        @RankReputation := IF(@PrevReputation = u.Reputation, @RankReputation, @RankReputation + 1) AS ReputationRank,
        @RankActivity := IF(@PrevLastAccessDate = u.LastAccessDate, @RankActivity, @RankActivity + 1) AS ActivityRank,
        @PrevReputation := u.Reputation,
        @PrevLastAccessDate := u.LastAccessDate
    FROM 
        Users u,
        (SELECT @RankReputation := 0, @RankActivity := 0, @PrevReputation := NULL, @PrevLastAccessDate := NULL) AS vars
    WHERE 
        u.LastAccessDate > (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    ORDER BY 
        u.Reputation DESC, u.LastAccessDate DESC
)
SELECT 
    au.UserId,
    au.DisplayName,
    COALESCE(ubc.GoldBadgeCount, 0) AS GoldBadgeCount,
    COALESCE(ubc.SilverBadgeCount, 0) AS SilverBadgeCount,
    COALESCE(ubc.BronzeBadgeCount, 0) AS BronzeBadgeCount,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.TotalQuestions, 0) AS TotalQuestions,
    COALESCE(ps.TotalAnswers, 0) AS TotalAnswers,
    COALESCE(ps.AvgScore, 0) AS AvgScore,
    COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
    CASE 
        WHEN COALESCE(ubc.GoldBadgeCount, 0) > 0 THEN 'Gold Achiever'
        WHEN COALESCE(ubc.SilverBadgeCount, 0) > 3 THEN 'Silver Contributor'
        ELSE 'Newcomer'
    END AS UserType
FROM 
    ActiveUsers au
LEFT JOIN 
    UserBadgeCounts ubc ON au.UserId = ubc.UserId
LEFT JOIN 
    PostStats ps ON au.UserId = ps.OwnerUserId
WHERE 
    (COALESCE(ubc.GoldBadgeCount, 0) > 0 OR COALESCE(ubc.SilverBadgeCount, 0) > 3 OR COALESCE(ubc.BronzeBadgeCount, 0) > 5)
    AND COALESCE(ps.TotalPosts, 0) IS NOT NULL
ORDER BY 
    au.Reputation DESC, 
    COALESCE(ps.TotalPosts, 0) DESC;
