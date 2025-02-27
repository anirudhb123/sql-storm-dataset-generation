WITH TagDetails AS (
    SELECT 
        Tags.TagName,
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Posts.ViewCount) AS TotalViewCount,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(Comments.Id IS NOT NULL::int) AS TotalComments,
        SUM(Votes.Id IS NOT NULL::int) AS TotalVotes
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id, Users.DisplayName
),
CombiningResults AS (
    SELECT 
        TD.TagName,
        TD.PostCount,
        TD.QuestionCount,
        TD.AnswerCount,
        TD.TotalViewCount,
        TD.AverageScore,
        UA.UserId,
        UA.DisplayName,
        UA.TotalPosts,
        UA.TotalQuestions,
        UA.TotalAnswers,
        UA.TotalComments,
        UA.TotalVotes
    FROM 
        TagDetails TD
    JOIN 
        UserActivity UA ON UA.TotalPosts > 0
)

SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViewCount,
    AverageScore,
    UserId,
    DisplayName,
    TotalPosts,
    TotalQuestions,
    TotalAnswers,
    TotalComments,
    TotalVotes
FROM 
    CombiningResults
ORDER BY 
    TotalViewCount DESC, 
    PostCount DESC; 
