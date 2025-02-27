WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.LastAccessDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.LastAccessDate
),
QuestionDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM Posts p
    WHERE p.PostTypeId = 1
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title AS ClosedTitle,
        ph.CreationDate,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
PostAnalytics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    us.DisplayName,
    us.Reputation,
    us.TotalBounties,
    us.QuestionCount,
    us.CommentCount,
    q.PostId,
    q.Title,
    q.CreationDate,
    q.Score,
    q.ViewCount,
    COALESCE(cp.ClosedTitle, 'Not Closed') AS PostStatus,
    cp.CloseReason,
    pa.CommentCount AS PostCommentCount,
    pa.UpVotes,
    pa.DownVotes
FROM UserStats us
JOIN QuestionDetails q ON us.UserId = q.PostId
LEFT JOIN ClosedPosts cp ON q.PostId = cp.ClosedPostId
LEFT JOIN PostAnalytics pa ON q.PostId = pa.PostId
WHERE us.Reputation > 1000
  AND q.LatestPostRank <= 5
ORDER BY us.Reputation DESC, q.ViewCount DESC
LIMIT 100;
