
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
        @rank := IF(@prev_reputation = Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Reputation
    FROM 
        UserStats, (SELECT @rank := 0, @prev_reputation := NULL) AS vars
    ORDER BY 
        Reputation DESC
), 
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts 
    JOIN 
        (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 
         UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers 
    ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE 
        PostTypeId = 1
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
    PopularTags pt
WHERE 
    tu.ReputationRank <= 10
ORDER BY 
    tu.Reputation DESC, pt.TagCount DESC;
