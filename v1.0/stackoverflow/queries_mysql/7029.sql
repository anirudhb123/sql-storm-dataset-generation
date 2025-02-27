mysql
WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
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
        AcceptedAnswers,
        TotalUpvotes,
        TotalDownvotes,
        (@row_number := @row_number + 1) AS Rank
    FROM 
        UserActivity, (SELECT @row_number := 0) AS r
    ORDER BY 
        TotalPosts DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.AcceptedAnswers,
    tu.TotalUpvotes,
    tu.TotalDownvotes,
    (tu.TotalUpvotes * 1.0 / NULLIF(tu.TotalPosts, 0)) AS UpvoteRatio,
    (tu.TotalDownvotes * 1.0 / NULLIF(tu.TotalPosts, 0)) AS DownvoteRatio
FROM 
    TopUsers tu
WHERE 
    tu.Rank <= 10
ORDER BY 
    tu.Rank;
