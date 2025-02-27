WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
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
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        GoldBadges,
        SilverBadges,
        BronzeBadges,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalPosts,
    tu.TotalComments,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    (SELECT COUNT(*) FROM Users) AS TotalUsers,
    COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 1) AS TotalQuestions,
    COUNT(DISTINCT p.Id) FILTER (WHERE p.PostTypeId = 2) AS TotalAnswers
FROM 
    TopUsers tu
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
WHERE 
    tu.Rank <= 10
GROUP BY 
    tu.DisplayName, tu.Reputation, tu.TotalPosts, tu.TotalComments, 
    tu.TotalUpVotes, tu.TotalDownVotes, tu.GoldBadges, 
    tu.SilverBadges, tu.BronzeBadges, tu.Rank
ORDER BY 
    tu.Rank;
