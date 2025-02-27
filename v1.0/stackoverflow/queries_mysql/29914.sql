
WITH TagStats AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1)) AS TagName,
        COUNT(*) AS PostCount,
        AVG(ViewCount) AS AvgViewCount,
        SUM(Score) AS TotalScore
    FROM 
        Posts
    JOIN 
        (SELECT a.N + 1 AS n FROM (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1))
), 
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AvgViewCount,
        TotalScore,
        @rank := @rank + 1 AS Rank
    FROM 
        TagStats, (SELECT @rank := 0) r
    WHERE 
        PostCount > 10 
    ORDER BY 
        PostCount DESC
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
        @rank2 := @rank2 + 1 AS Rank
    FROM 
        UserActivity, (SELECT @rank2 := 0) r2
    WHERE 
        TotalPosts > 5  
    ORDER BY 
        TotalPosts DESC
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
