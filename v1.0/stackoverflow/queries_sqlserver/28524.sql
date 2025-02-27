
WITH TagCount AS (
    SELECT 
        LTRIM(RTRIM(tag)) AS TagName,
        COUNT(*) AS PostCount
    FROM (
        SELECT 
            value AS tag
        FROM 
            Posts
        CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
        WHERE 
            PostTypeId = 1  
    ) AS extracted_tags
    GROUP BY 
        LTRIM(RTRIM(tag))
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
        SUM(ISNULL(Posts.AnswerCount, 0)) AS TotalAnswers,
        SUM(ISNULL(Posts.Score, 0)) AS TotalScore
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
        value AS TagName,
        Users.DisplayName AS Owner
    FROM 
        Posts
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    CROSS APPLY STRING_SPLIT(SUBSTRING(Posts.Tags, 2, LEN(Posts.Tags) - 2), '><')
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
