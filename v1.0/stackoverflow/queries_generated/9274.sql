WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(DATEDIFF(NOW(), p.CreationDate)) AS AvgPostAge
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        BadgeCount,
        PostCount,
        AvgPostAge,
        RANK() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStatistics
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.Upvotes,
    tu.Downvotes,
    tu.BadgeCount,
    tu.PostCount,
    tu.AvgPostAge
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
