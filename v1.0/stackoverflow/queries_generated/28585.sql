WITH TagStatistics AS (
    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(Posts.ViewCount) AS TotalViewCount,
        AVG(Posts.Score) AS AverageScore
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
),
UserEngagement AS (
    SELECT 
        Users.DisplayName,
        COUNT(Comments.Id) AS CommentCount,
        SUM(Votes.VoteTypeId = 2) AS UpVotes,
        SUM(Votes.VoteTypeId = 3) AS DownVotes
    FROM 
        Users
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Votes ON Users.Id = Votes.UserId
    GROUP BY 
        Users.DisplayName
),
TopTags AS (
    SELECT 
        TagStatistics.TagName,
        TagStatistics.PostCount,
        TagStatistics.QuestionCount,
        TagStatistics.AnswerCount,
        TagStatistics.TotalViewCount,
        TagStatistics.AverageScore,
        RANK() OVER (ORDER BY TagStatistics.PostCount DESC) AS TagRank
    FROM 
        TagStatistics
)
SELECT 
    TopTags.TagName,
    TopTags.PostCount,
    TopTags.QuestionCount,
    TopTags.AnswerCount,
    TopTags.TotalViewCount,
    TopTags.AverageScore,
    UserEngagement.DisplayName,
    UserEngagement.CommentCount,
    UserEngagement.UpVotes,
    UserEngagement.DownVotes
FROM 
    TopTags
JOIN 
    UserEngagement ON UserEngagement.CommentCount > 10
WHERE 
    TopTags.TagRank <= 10 -- Get the top 10 tags with most posts
ORDER BY 
    TopTags.PostCount DESC, UserEngagement.UpVotes DESC;
