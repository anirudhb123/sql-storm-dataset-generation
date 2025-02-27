WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersProvided,
        COUNT(c.Id) AS CommentsMade,
        SUM(v.VoteTypeId = 3) AS DownVotesReceived,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.DisplayName
), 
TagStatistics AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveScoredPosts
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
), 
PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionsAsked,
    ua.AnswersProvided,
    ua.CommentsMade,
    ua.DownVotesReceived,
    ua.UpVotesReceived,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.PositiveScoredPosts,
    phs.EditCount,
    phs.CloseCount,
    phs.ReopenCount
FROM UserActivity ua
LEFT JOIN TagStatistics ts ON ts.PostCount > 0
LEFT JOIN PostHistoryStats phs ON phs.PostId IN (
    SELECT p.Id 
    FROM Posts p 
    WHERE p.OwnerUserId = ua.UserId
)
ORDER BY ua.UpVotesReceived DESC, ua.QuestionsAsked DESC;
