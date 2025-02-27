WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS TotalUpvotedPosts,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS TotalDownvotedPosts,
        COUNT(DISTINCT c.Id) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalAnswers,
        TotalQuestions,
        TotalUpvotedPosts,
        TotalDownvotedPosts,
        TotalComments,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank,
        RANK() OVER (ORDER BY TotalAnswers DESC) AS AnswerRank,
        RANK() OVER (ORDER BY TotalUpvotedPosts DESC) AS UpvoteRank,
        RANK() OVER (ORDER BY TotalComments DESC) AS CommentRank
    FROM 
        UserActivity
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS UsageCount
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        pt.Name = 'Question'
    GROUP BY 
        t.TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalAnswers,
    tu.TotalQuestions,
    tu.TotalUpvotedPosts,
    tu.TotalDownvotedPosts,
    tu.TotalComments,
    pt.TagName AS PopularTag
FROM 
    TopUsers tu
CROSS JOIN 
    PopularTags pt
WHERE 
    tu.PostRank <= 10 OR tu.AnswerRank <= 10
ORDER BY 
    tu.PostRank, tu.AnswerRank;
