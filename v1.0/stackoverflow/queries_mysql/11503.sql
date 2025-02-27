
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStatistics, (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    TotalComments,
    TotalUpVotes,
    TotalDownVotes
FROM 
    TopUsers
WHERE 
    Rank <= 10;
