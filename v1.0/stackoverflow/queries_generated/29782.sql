WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS TotalQuestions,
        AVG(COALESCE(v.Score, 0)) AS AvgPostScore,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        u.Reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
TagPostStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS TotalPostsWithTag,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS TotalAnswersWithTag
    FROM 
        Tags t
    JOIN 
        Posts p ON p.Tags LIKE '%<' || t.TagName || '>%' 
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        t.TagName
),
TopUsers AS (
    SELECT 
        ups.UserId,
        ups.DisplayName,
        ups.TotalPosts,
        ups.TotalAnswers,
        ups.TotalQuestions,
        ups.AvgPostScore,
        ups.LastPostDate,
        ROW_NUMBER() OVER (ORDER BY ups.AvgPostScore DESC, ups.TotalPosts DESC) AS UserRank
    FROM 
        UserPostStats ups
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalAnswers,
    tu.TotalQuestions,
    tu.AvgPostScore,
    tu.LastPostDate,
    tps.TagName,
    tps.TotalPostsWithTag,
    tps.TotalAnswersWithTag
FROM 
    TopUsers tu
LEFT JOIN 
    TagPostStats tps ON tu.TotalPosts > 0
WHERE 
    tu.UserRank <= 10
ORDER BY 
    tu.AvgPostScore DESC, 
    tu.TotalPosts DESC;
