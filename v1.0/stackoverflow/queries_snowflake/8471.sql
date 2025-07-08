
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(p.Score, 0)) AS AverageScore,
        AVG(COALESCE(p.ViewCount, 0)) AS AverageViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        AverageScore,
        AverageViewCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
), 
PopularTags AS (
    SELECT 
        SPLIT(Tags, '><') AS TagArray
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
), 
FlattenedTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagCount
    FROM 
        PopularTags,
        LATERAL FLATTEN(INPUT => TagArray) AS Tag
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    tu.DisplayName AS TopUser,
    tu.Reputation AS UserReputation,
    tu.PostCount AS TotalPosts,
    tu.QuestionCount AS TotalQuestions,
    tu.AnswerCount AS TotalAnswers,
    tu.AverageScore AS AvgScore,
    tu.AverageViewCount AS AvgViews,
    pt.Tag AS PopularTag,
    pt.TagCount AS NumberOfPosts
FROM 
    TopUsers tu
CROSS JOIN 
    FlattenedTags pt
WHERE 
    tu.ReputationRank <= 10
ORDER BY 
    tu.Reputation DESC, pt.TagCount DESC;
