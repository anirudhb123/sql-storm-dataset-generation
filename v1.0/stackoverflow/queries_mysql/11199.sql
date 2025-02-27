
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 2 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        Questions,
        Answers,
        AcceptedAnswers,
        @rank := @rank + 1 AS Rank
    FROM 
        UserReputation,
        (SELECT @rank := 0) r
    ORDER BY 
        Reputation DESC
)
SELECT 
    UserId,
    Reputation,
    TotalPosts,
    Questions,
    Answers,
    AcceptedAnswers
FROM 
    TopUsers
WHERE 
    Rank <= 10;
