WITH TagAnalysis AS (
    SELECT 
        Tags.TagName,
        COUNT(DISTINCT Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(Posts.Score) AS AverageScore,
        MAX(Posts.CreationDate) AS LatestPostDate
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags) - 2), '><')::int[]) 
    GROUP BY 
        Tags.TagName
),
UserActivity AS (
    SELECT 
        Users.DisplayName,
        COUNT(Posts.Id) AS TotalPosts,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(Comments.Score) AS TotalCommentScore,
        SUM(Votes.VoteTypeId = 2) AS TotalUpvotes,
        SUM(Votes.VoteTypeId = 3) AS TotalDownvotes,
        AVG(U.Views) AS AvgViews
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id
),
Benchmark AS (
    SELECT 
        a.TagName,
        a.PostCount,
        a.QuestionCount,
        a.AnswerCount,
        a.AverageScore,
        a.LatestPostDate,
        COALESCE(ua.TotalPosts, 0) AS UserPostCount,
        COALESCE(ua.TotalQuestions, 0) AS UserQuestionCount,
        COALESCE(ua.TotalAnswers, 0) AS UserAnswerCount,
        COALESCE(ua.TotalCommentScore, 0) AS UserCommentTotalScore,
        COALESCE(ua.TotalUpvotes, 0) AS UserUpvotes,
        COALESCE(ua.TotalDownvotes, 0) AS UserDownvotes,
        COALESCE(ua.AvgViews, 0) AS UserAvgViews
    FROM 
        TagAnalysis a
    LEFT JOIN 
        UserActivity ua ON TRUE -- This join will retrieve user activity for all users
)
SELECT 
    ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS Rank,
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    AverageScore,
    LatestPostDate,
    UserPostCount,
    UserQuestionCount,
    UserAnswerCount,
    UserCommentTotalScore,
    UserUpvotes,
    UserDownvotes,
    UserAvgViews
FROM 
    Benchmark
ORDER BY 
    TagName;
