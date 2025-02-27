WITH UserVoteStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        AVG(p.Score) AS AveragePostScore
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON v.PostId = p.Id
    GROUP BY u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 ELSE 0 END) AS EditHistoryCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate
),
UserPostDetails AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        us.UpVotes,
        us.DownVotes,
        us.TotalPosts,
        us.AveragePostScore,
        ps.EditHistoryCount
    FROM UserVoteStats us
    JOIN Posts ps ON us.UserId = ps.OwnerUserId
    JOIN Users u ON ps.OwnerUserId = u.Id
)
SELECT 
    UserId,
    DisplayName,
    COUNT(PostId) AS NumberOfPosts,
    AVG(CommentCount) AS AvgCommentsPerPost,
    SUM(UpVotes) AS TotalUpVotes,
    SUM(DownVotes) AS TotalDownVotes,
    AVG(AveragePostScore) AS AvgPostScore,
    SUM(EditHistoryCount) AS TotalEdits
FROM UserPostDetails
GROUP BY UserId, DisplayName
ORDER BY TotalUpVotes DESC, NumberOfPosts DESC;
