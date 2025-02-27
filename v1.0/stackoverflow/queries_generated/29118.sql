WITH TagStatistics AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserReputation AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        SUM(Posts.Score) AS TotalScore
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
),
TopTags AS (
    SELECT 
        TagStatistics.TagName, 
        TagStatistics.PostCount, 
        TagStatistics.QuestionCount, 
        TagStatistics.AnswerCount, 
        TagStatistics.AverageScore,
        RANK() OVER (ORDER BY TagStatistics.PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)

SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalScore,
    tt.TagName,
    tt.PostCount,
    tt.QuestionCount,
    tt.AnswerCount,
    tt.AverageScore
FROM 
    UserReputation u
INNER JOIN 
    TopTags tt ON tt.TagRank <= 5 -- Joining top 5 tags by post count
WHERE 
    u.TotalPosts > 10 -- Only considering users with more than 10 posts
ORDER BY 
    u.TotalScore DESC, tt.PostCount DESC;

This SQL query consists of multiple Common Table Expressions (CTEs) and aims to demonstrate string processing by extracting relevant tags from the `Posts` table while also analyzing user performance through statistics. It ranks the top tags based on the number of posts, aggregates user reputation by the number and scores of posts, and finally joins the two datasets to provide a comprehensive view of user activity associated with top-performing tags.
