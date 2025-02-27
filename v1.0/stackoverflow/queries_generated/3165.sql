WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore,
        COUNT(DISTINCT pa.Id) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Posts pa ON u.Id = pa.OwnerUserId AND pa.AcceptedAnswerId IS NOT NULL
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
        AvgScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS UserRank
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
),
PopularTags AS (
    SELECT 
        TRIM(BOTH '<>' FROM unnest(string_to_array(Tags, '> <'))) AS Tag,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.TotalPosts,
    tu.TotalQuestions,
    tu.TotalAnswers,
    tu.AvgScore,
    pt.Tag,
    pt.TagCount
FROM 
    TopUsers tu
FULL OUTER JOIN 
    PopularTags pt ON tu.TotalQuestions > 10
WHERE 
    tu.UserRank <= 100 OR pt.Tag IS NOT NULL
ORDER BY 
    tu.AvgScore DESC, pt.TagCount DESC;
