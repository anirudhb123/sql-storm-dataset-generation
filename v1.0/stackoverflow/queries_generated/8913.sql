WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.Reputation, u.DisplayName
),
PostDetails AS (
    SELECT 
        p.Id AS PostId, 
        p.Title,
        p.CreationDate,
        p.Score, 
        p.ViewCount, 
        u.DisplayName AS OwnerDisplayName,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        COALESCE(cl.CloseReasonId, 0) AS Closed
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT ph.PostId, MIN(ph.Comment) AS CloseReasonId
        FROM PostHistory ph
        WHERE ph.PostHistoryTypeId = 10
        GROUP BY ph.PostId
    ) cl ON p.Id = cl.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.Reputation,
    us.PostCount,
    us.AnswerCount,
    us.BadgeCount,
    us.UpVoteCount,
    us.DownVoteCount,
    pd.PostId,
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.Closed
FROM UserStats us
JOIN PostDetails pd ON us.UserId = pd.OwnerUserId
ORDER BY us.Reputation DESC, pd.Score DESC
LIMIT 50 OFFSET 0;
