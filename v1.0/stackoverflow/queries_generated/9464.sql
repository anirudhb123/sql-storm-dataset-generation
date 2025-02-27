WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(b.Class) AS TotalBadges,
        SUM(v.VoteCount) AS TotalVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId 
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS VoteCount FROM Votes GROUP BY PostId) v ON p.Id = v.PostId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 0 AND u.CreationDate < NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.Reputation, u.DisplayName, u.CreationDate
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        DisplayName,
        PostCount,
        CommentCount,
        TotalBadges,
        TotalVotes,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        UserStats
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.CommentCount,
    tu.TotalBadges,
    tu.TotalVotes
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Reputation DESC;
