WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions
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
        TotalScore, 
        TotalPosts, 
        TotalAnswers, 
        TotalQuestions,
        RANK() OVER (ORDER BY TotalScore DESC) AS Rank
    FROM 
        UserReputation
),
PopularTags AS (
    SELECT 
        t.TagName, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC
    LIMIT 10
)
SELECT 
    tu.DisplayName, 
    tu.TotalScore, 
    tu.TotalPosts, 
    tu.TotalAnswers, 
    tu.TotalQuestions, 
    pt.TagName, 
    pt.PostCount
FROM 
    TopUsers tu
CROSS JOIN 
    PopularTags pt
WHERE 
    tu.Rank <= 5
ORDER BY 
    tu.TotalScore DESC, pt.PostCount DESC;
