
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 3 THEN 1 ELSE 0 END) AS Wikis,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        @row_number := @row_number + 1 AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId,
        (SELECT @row_number := 0) AS rn
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate, u.LastAccessDate
),
TopUsers AS (
    SELECT 
        *,
        (@dense_rank := CASE WHEN @prev_reputation = Reputation THEN @dense_rank ELSE @dense_rank + 1 END) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserActivity,
        (SELECT @dense_rank := 0, @prev_reputation := null) AS r
    ORDER BY 
        Reputation DESC
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.Questions,
    tu.Answers,
    tu.Wikis,
    tu.Upvotes,
    tu.Downvotes,
    tu.Reputation,
    tu.Rank,
    tu.ReputationRank
FROM 
    TopUsers tu
WHERE 
    tu.ReputationRank <= 10
ORDER BY 
    tu.Reputation DESC, 
    tu.TotalPosts DESC;
