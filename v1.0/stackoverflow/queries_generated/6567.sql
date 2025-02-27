WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount, 
        COUNT(DISTINCT b.Id) AS BadgeCount, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes, 
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount, 
        p.AnswerCount, 
        p.CommentCount, 
        COALESCE(COUNT(DISTINCT c.Id), 0) AS CommentCount,
        COALESCE(COUNT(DISTINCT ph.Id), 0) AS HistoryCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.AnswerCount, p.CommentCount
)
SELECT 
    us.UserId, 
    us.DisplayName, 
    us.Reputation, 
    us.PostCount, 
    us.BadgeCount, 
    us.UpVotes, 
    us.DownVotes,
    ps.PostId,
    ps.Title,
    ps.CreationDate,
    ps.Score,
    ps.ViewCount,
    ps.AnswerCount,
    ps.CommentCount,
    ps.HistoryCount
FROM UserStats us
JOIN PostStats ps ON us.UserId = ps.OwnerUserId
ORDER BY us.Reputation DESC, ps.Score DESC
LIMIT 100;
