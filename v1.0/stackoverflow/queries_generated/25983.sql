WITH TagStats AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COUNT(DISTINCT Posts.Id) AS TotalPosts,
        COUNT(DISTINCT Comments.Id) AS TotalComments,
        SUM(Votes.VoteTypeId = 2) AS UpVotesReceived,
        SUM(Votes.VoteTypeId = 3) AS DownVotesReceived
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN 
        Comments ON Users.Id = Comments.UserId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Users.Id
),
RecentActivity AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        MAX(Posts.CreationDate) AS LastPostDate,
        PostHistory.CreationDate AS LastEditDate,
        Users.DisplayName AS LastEditor
    FROM 
        Posts
    LEFT JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    LEFT JOIN 
        Users ON PostHistory.UserId = Users.Id
    GROUP BY 
        Posts.Id, Posts.Title, PostHistory.CreationDate, Users.DisplayName
)
SELECT 
    Tags.Tag,
    TagStats.PostCount,
    TagStats.QuestionCount,
    TagStats.AnswerCount,
    Users.DisplayName AS TopUser,
    UserActivity.TotalPosts,
    UserActivity.TotalComments,
    UserActivity.UpVotesReceived - UserActivity.DownVotesReceived AS NetVotes,
    RecentActivity.LastPostDate,
    RecentActivity.LastEditor
FROM 
    TagStats
JOIN 
    Users ON UserActivity.TotalPosts > (SELECT AVG(TotalPosts) FROM UserActivity) 
    JOIN 
    UserActivity ON Users.Id = UserActivity.UserId
JOIN 
    RecentActivity ON RecentActivity.PostId = (SELECT Id FROM Posts WHERE Tags ILIKE '%' || TagStats.Tag || '%' LIMIT 1)
ORDER BY 
    TagStats.PostCount DESC, UserActivity.UpVotesReceived DESC;
