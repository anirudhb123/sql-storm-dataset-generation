
WITH TagStats AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore
    FROM 
        Posts,
        LATERAL FLATTEN(input => SPLIT(SUBSTR(Tags, 2, LEN(Tags) - 2), '><'))  
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(value)
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AvgViewCount,
        TotalScore,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagStats
    WHERE 
        PostCount > 10 
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        SUM(COALESCE(c.Score, 0)) AS TotalCommentScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        u.Reputation > 1000  
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionsCount,
        AnswersCount,
        TotalCommentScore,
        ROW_NUMBER() OVER (ORDER BY TotalPosts DESC) AS Rank
    FROM 
        UserActivity
    WHERE 
        TotalPosts > 5  
)
SELECT 
    t.TagName,
    t.PostCount,
    t.AvgViewCount,
    t.TotalScore,
    u.DisplayName AS TopUser,
    u.TotalPosts,
    u.QuestionsCount,
    u.AnswersCount,
    u.TotalCommentScore
FROM 
    TopTags t
LEFT JOIN 
    TopUsers u ON t.Rank = u.Rank
ORDER BY 
    t.PostCount DESC, 
    u.TotalPosts DESC;
