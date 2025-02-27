
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViewCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        TotalScore,
        AvgViewCount,
        @row_number := IF(@prev_score = TotalScore, @row_number, @row_number + 1) AS ScoreRank,
        @prev_score := TotalScore
    FROM 
        UserPostStats, (SELECT @row_number := 0, @prev_score := NULL) AS vars
    ORDER BY 
        TotalScore DESC
),
PopularTags AS (
    SELECT 
        TagName,
        COUNT(*) AS TagCount
    FROM 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '<>', numbers.n), '<>', -1)) AS TagName
         FROM Posts
         JOIN (SELECT a.N + b.N * 10 + 1 n
               FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
                     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
               (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 
                     UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b
              ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '<>', '')) >= numbers.n - 1) AS TagsList
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        @tag_row_number := IF(@prev_tag_count = TagCount, @tag_row_number, @tag_row_number + 1) AS TagRank,
        @prev_tag_count := TagCount
    FROM 
        PopularTags, (SELECT @tag_row_number := 0, @prev_tag_count := NULL) AS vars
    ORDER BY 
        TagCount DESC
)
SELECT 
    tu.DisplayName,
    tu.TotalPosts,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    tu.AvgViewCount,
    tt.TagName,
    tt.TagCount
FROM 
    TopUsers tu
JOIN 
    TopTags tt ON tu.QuestionCount > 10 AND tu.AnswerCount > 30
WHERE 
    tu.ScoreRank <= 10 AND tt.TagRank <= 5
ORDER BY 
    tu.TotalScore DESC, tt.TagCount DESC;
