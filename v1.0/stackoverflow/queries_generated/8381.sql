WITH UserScoreSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Comments c ON c.UserId = u.Id
        LEFT JOIN Votes v ON v.UserId = u.Id
        LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE 
        u.Reputation > 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalScore,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        TotalBadges,
        ROW_NUMBER() OVER (ORDER BY TotalScore DESC, Reputation DESC) AS Rank
    FROM 
        UserScoreSummary
)
SELECT 
    Rank,
    UserId,
    DisplayName,
    Reputation,
    TotalScore,
    TotalPosts,
    TotalComments,
    TotalUpvotes,
    TotalDownvotes,
    TotalBadges
FROM 
    TopUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
