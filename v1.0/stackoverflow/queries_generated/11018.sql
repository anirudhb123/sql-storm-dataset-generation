-- Performance Benchmarking Query

WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(v.VoteTypeId = 2) AS UpVotesReceived, -- UpMod
        SUM(v.VoteTypeId = 3) AS DownVotesReceived -- DownMod
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        u.CreationDate >= '2020-01-01' -- Filter for newly created users
    GROUP BY u.Id, u.Reputation
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        MAX(p.CreationDate) AS LatestActivityDate
    FROM Posts p
    WHERE 
        p.CreationDate >= '2020-01-01' -- Filter for newly created posts
    GROUP BY p.Id, p.Title, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount, p.FavoriteCount
)
SELECT 
    us.UserId,
    us.Reputation,
    us.PostCount,
    us.UpVotesReceived,
    us.DownVotesReceived,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.FavoriteCount,
    ps.LatestActivityDate
FROM UserStatistics us
JOIN PostStatistics ps ON us.UserId = ps.OwnerUserId
ORDER BY us.Reputation DESC, ps.Score DESC;
