
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(u.Reputation) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes,
        AvgReputation,
        @rank := IF(@prev_TotalPosts = TotalPosts, @rank, @rank + 1) AS Rank,
        @prev_TotalPosts := TotalPosts
    FROM 
        UserStats, (SELECT @rank := 0, @prev_TotalPosts := NULL) r
    ORDER BY 
        TotalPosts DESC, TotalUpvotes DESC
)
SELECT 
    t.DisplayName,
    t.TotalPosts,
    t.TotalComments,
    t.TotalUpvotes,
    t.TotalDownvotes,
    t.AvgReputation
FROM 
    TopUsers t
WHERE 
    t.Rank <= 10
ORDER BY 
    t.Rank, t.TotalPosts DESC;
