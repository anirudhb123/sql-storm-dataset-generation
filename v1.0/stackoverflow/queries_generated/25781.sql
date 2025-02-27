WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
PostStatistics AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(CASE WHEN p.PostTypeId = 1 THEN 1 END) AS TotalQuestions,
        COUNT(CASE WHEN p.PostTypeId = 2 THEN 1 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore
    FROM
        Posts p
    GROUP BY
        p.OwnerUserId
),
CombinedStats AS (
    SELECT
        u.DisplayName,
        ur.Reputation,
        ur.BadgeCount,
        ur.GoldBadges,
        ur.SilverBadges,
        ur.BronzeBadges,
        ps.TotalPosts,
        ps.TotalQuestions,
        ps.TotalAnswers,
        ps.TotalScore
    FROM
        UserReputation ur
    JOIN
        PostStatistics ps ON ur.UserId = ps.OwnerUserId
    ORDER BY
        ur.Reputation DESC
    LIMIT 10
)
SELECT
    *,
    CONCAT( 
        'User ', DisplayName, 
        ' has ', TotalPosts, ' posts including ', 
        TotalQuestions, ' questions and ', 
        TotalAnswers, ' answers. Total Score: ', 
        TotalScore, '. Badges earned: ', 
        GoldBadges, ' Gold, ', 
        SilverBadges, ' Silver, ', 
        BronzeBadges, ' Bronze.'
    ) AS BenchmarkString
FROM
    CombinedStats;
