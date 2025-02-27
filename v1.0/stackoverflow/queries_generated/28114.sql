WITH TagStats AS (
    SELECT 
        Tags.TagName, 
        COUNT(DISTINCT Posts.Id) AS PostCount, 
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(Posts.ViewCount) AS TotalViewCount,
        AVG(Users.Reputation) AS AvgUserReputation,
        STRING_AGG(DISTINCT Users.DisplayName, ', ') AS TopContributors
    FROM 
        Tags
    JOIN 
        Posts ON Tags.Id = ANY(string_to_array(Posts.Tags, '><'))::int[]
    JOIN 
        Users ON Posts.OwnerUserId = Users.Id
    GROUP BY 
        Tags.TagName
),
PostActivity AS (
    SELECT 
        Posts.Id AS PostId,
        Posts.Title,
        COUNT(Comments.Id) AS CommentCount,
        COUNT(Votes.Id) FILTER (WHERE Votes.VoteTypeId = 2) AS UpvoteCount, 
        COUNT(Votes.Id) FILTER (WHERE Votes.VoteTypeId = 3) AS DownvoteCount,
        (EXTRACT(EPOCH FROM MAX(Comments.CreationDate)) - EXTRACT(EPOCH FROM Posts.CreationDate)) AS DurationInSeconds
    FROM 
        Posts
    LEFT JOIN 
        Comments ON Posts.Id = Comments.PostId
    LEFT JOIN 
        Votes ON Posts.Id = Votes.PostId
    GROUP BY 
        Posts.Id, Posts.Title
),
PostHistoryStats AS (
    SELECT 
        Posts.Id AS PostId,
        COUNT(PostHistory.Id) AS EditCount,
        MAX(PostHistory.CreationDate) AS LastEditDate
    FROM 
        Posts
    JOIN 
        PostHistory ON Posts.Id = PostHistory.PostId
    GROUP BY 
        Posts.Id
)
SELECT 
    ts.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.TotalViewCount,
    ts.AvgUserReputation,
    ts.TopContributors,
    pa.PostId,
    pa.Title,
    pa.CommentCount,
    pa.UpvoteCount,
    pa.DownvoteCount,
    pa.DurationInSeconds,
    phs.EditCount,
    phs.LastEditDate
FROM 
    TagStats ts
JOIN 
    PostActivity pa ON ts.PostCount > 0 AND pa.PostId IN (SELECT Posts.Id FROM Posts JOIN Tags ON Tags.Id = ANY(string_to_array(Posts.Tags, '><'))::int[])
JOIN 
    PostHistoryStats phs ON pa.PostId = phs.PostId
ORDER BY 
    ts.PostCount DESC, ts.TotalViewCount DESC;
