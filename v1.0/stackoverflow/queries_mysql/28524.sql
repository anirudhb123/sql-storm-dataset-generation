
WITH TagCount AS (
    SELECT 
        TRIM(tag) AS TagName,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '><', numbers.n), '><', -1) AS tag
        FROM 
            Posts
        INNER JOIN (
            SELECT 
                a.N + b.N * 10 + 1 n
            FROM 
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
            ORDER BY n
        ) numbers ON CHAR_LENGTH(Posts.Tags) - CHAR_LENGTH(REPLACE(Posts.Tags, '><', '')) >= numbers.n - 1
        WHERE 
            Posts.PostTypeId = 1  
    ) AS extracted_tags
    GROUP BY 
        TRIM(tag)
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank
    FROM 
        TagCount
    WHERE 
        PostCount > 1  
),
MostActiveUsers AS (
    SELECT 
        Users.DisplayName,
        Users.Reputation,
        COUNT(Posts.Id) AS QuestionsAnswered,
        SUM(IFNULL(Posts.AnswerCount, 0)) AS TotalAnswers,
        SUM(IFNULL(Posts.Score, 0)) AS TotalScore
    FROM 
        Users
    JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    WHERE 
        Posts.PostTypeId = 2  
    GROUP BY 
        Users.DisplayName, Users.Reputation
),
TagUsage AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        Posts.CreationDate,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Posts.Tags, '><', numbers.n), '><', -1) AS TagName,
        Users.DisplayName AS Owner
    FROM 
        Posts
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    INNER JOIN (
        SELECT 
            a.N + b.N * 10 + 1 n
        FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ORDER BY n
    ) numbers ON CHAR_LENGTH(Posts.Tags) - CHAR_LENGTH(REPLACE(Posts.Tags, '><', '')) >= numbers.n - 1
    WHERE 
        Posts.PostTypeId = 1  
)
SELECT 
    TopTags.TagName,
    TopTags.PostCount,
    MostActiveUsers.DisplayName,
    MostActiveUsers.Reputation,
    MostActiveUsers.QuestionsAnswered,
    MostActiveUsers.TotalAnswers,
    MostActiveUsers.TotalScore,
    COUNT(TagUsage.PostId) AS TagPostCount,
    MIN(TagUsage.CreationDate) AS EarliestPostDate,
    MAX(TagUsage.CreationDate) AS LatestPostDate
FROM 
    TopTags
JOIN 
    TagUsage ON TopTags.TagName = TagUsage.TagName
JOIN 
    MostActiveUsers ON TagUsage.Owner = MostActiveUsers.DisplayName
GROUP BY 
    TopTags.TagName, 
    TopTags.PostCount,
    MostActiveUsers.DisplayName, 
    MostActiveUsers.Reputation, 
    MostActiveUsers.QuestionsAnswered, 
    MostActiveUsers.TotalAnswers,
    MostActiveUsers.TotalScore
ORDER BY 
    TopTags.PostCount DESC, MostActiveUsers.TotalScore DESC
LIMIT 10;
