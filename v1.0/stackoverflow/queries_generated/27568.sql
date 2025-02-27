WITH TagStatistics AS (
    SELECT 
        tags.TagName,
        COUNT(posts.Id) AS PostCount,
        SUM(CASE WHEN posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN votes.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN votes.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        COALESCE(ROUND(SUM(CASE WHEN posts.ViewCount > 0 THEN posts.ViewCount ELSE 0 END) * 1.0 / NULLIF(COUNT(posts.Id), 0), 2), 0) AS AvgViewsPerPost
    FROM 
        Tags tags
    LEFT JOIN 
        Posts posts ON tags.Id = ANY(string_to_array(posts.Tags, ',')::int[])
    LEFT JOIN 
        Votes votes ON posts.Id = votes.PostId
    GROUP BY 
        tags.TagName
),
UserEngagement AS (
    SELECT 
        users.DisplayName,
        COALESCE(SUM(CASE WHEN posts.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionsAsked,
        COALESCE(SUM(CASE WHEN votes.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN votes.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived,
        COALESCE(SUM(comments.Id), 0) AS TotalComments
    FROM 
        Users users
    LEFT JOIN 
        Posts posts ON users.Id = posts.OwnerUserId
    LEFT JOIN 
        Votes votes ON posts.Id = votes.PostId
    LEFT JOIN 
        Comments comments ON posts.Id = comments.PostId
    GROUP BY 
        users.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        PostCount,
        AvgViewsPerPost
    FROM 
        TagStatistics
    WHERE 
        PostCount > 10
    ORDER BY 
        AvgViewsPerPost DESC
    LIMIT 5
)
SELECT 
    ue.DisplayName,
    ue.QuestionsAsked,
    ue.UpvotesReceived,
    ue.DownvotesReceived,
    ue.TotalComments,
    tt.TagName,
    tt.PostCount,
    tt.AvgViewsPerPost
FROM 
    UserEngagement ue
INNER JOIN 
    TopTags tt ON ue.DisplayName IN (SELECT DISTINCT unnest(string_to_array(tt.TagName, ' ')))
ORDER BY 
    ue.UpvotesReceived DESC, 
    ue.QuestionsAsked DESC;
