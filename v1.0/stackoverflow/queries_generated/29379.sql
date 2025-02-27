WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalVotes,
        TotalBadges,
        TotalQuestions,
        TotalAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS RepuRank,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalVotes DESC) AS VoteRank
    FROM 
        UserStatistics
),
BadgesSummary AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalVotes,
    tu.TotalBadges,
    bs.GoldBadges,
    bs.SilverBadges,
    bs.BronzeBadges,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.RepuRank,
    tu.PostRank,
    tu.VoteRank
FROM 
    TopUsers tu
JOIN 
    BadgesSummary bs ON tu.UserId = bs.UserId
WHERE 
    tu.RepuRank <= 10 OR tu.PostRank <= 10 OR tu.VoteRank <= 10
ORDER BY 
    tu.Reputation DESC,
    tu.TotalPosts DESC,
    tu.TotalVotes DESC;
