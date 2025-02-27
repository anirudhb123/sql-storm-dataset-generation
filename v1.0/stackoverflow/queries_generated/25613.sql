WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.ViewCount > 1000 THEN 1 ELSE 0 END) AS PostsOver1000Views,
        AVG(COALESCE(p.Score, 0)) AS AvgPostScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        PostsOver1000Views,
        AvgPostScore,
        DENSE_RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        UserPostStats
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.PostsOver1000Views,
    tu.AvgPostScore,
    COALESCE(SUM(b.Class), 0) AS TotalBadges,
    ARRAY_AGG(DISTINCT bt.Name) AS BadgeTypes,
    ARRAY_AGG(DISTINCT t.TagName) AS PopularTags
FROM 
    TopUsers tu
LEFT JOIN 
    Badges b ON tu.UserId = b.UserId
LEFT JOIN 
    Posts p ON tu.UserId = p.OwnerUserId
LEFT JOIN 
    UNNEST(STRING_TO_ARRAY(p.Tags, '>')) AS tag ON TRUE
LEFT JOIN 
    Tags t ON tag = t.TagName
WHERE 
    tu.PostRank <= 10
GROUP BY 
    tu.UserId, tu.DisplayName, tu.TotalPosts, tu.TotalQuestions, tu.TotalAnswers, tu.PostsOver1000Views, tu.AvgPostScore
ORDER BY 
    tu.PostRank;
