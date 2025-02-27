
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes,
        AVG(p.Score) AS AveragePostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
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
        TotalQuestions,
        TotalAnswers,
        TotalUpvotes,
        TotalDownvotes,
        AveragePostScore,
        @rank := IF(@prev = TotalPosts, @rank, @rank + 1) AS PostRank,
        @prev := TotalPosts
    FROM 
        UserPostStats, (SELECT @rank := 0, @prev := NULL) AS vars
    ORDER BY 
        TotalPosts DESC
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalUpvotes,
    TotalDownvotes,
    AveragePostScore,
    PostRank
FROM 
    TopUsers
WHERE 
    PostRank <= 10;
