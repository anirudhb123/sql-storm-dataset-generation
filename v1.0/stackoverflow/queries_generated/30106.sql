WITH RECURSIVE UserBadgeCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(NULLIF(VoteMetrics.UpVotes, 0), NULL) AS UpVotes,
        COALESCE(NULLIF(VoteMetrics.DownVotes, 0), NULL) AS DownVotes,
        COALESCE(NULLIF(c.CommentCount, 0), NULL) AS CommentCount,
        RANK() OVER (ORDER BY COALESCE(NULLIF(VoteMetrics.UpVotes, 0), 0) - COALESCE(NULLIF(VoteMetrics.DownVotes, 0), 0) DESC) AS Rank
    FROM Posts p
    LEFT JOIN (
        SELECT 
            PostId, 
            SUM(CASE WHEN vt.Name = 'UpMod' THEN 1 ELSE 0 END) AS UpVotes,
            SUM(CASE WHEN vt.Name = 'DownMod' THEN 1 ELSE 0 END) AS DownVotes
        FROM Votes v
        JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
        GROUP BY PostId
    ) VoteMetrics ON p.Id = VoteMetrics.PostId
    JOIN (
        SELECT 
            PostId, 
            COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10 -- Closed
    GROUP BY p.Id
)
SELECT 
    u.DisplayName,
    ub.BadgeCount,
    pm.PostId,
    pm.Title,
    pm.ViewCount,
    pm.UpVotes,
    pm.DownVotes,
    pm.CommentCount,
    CASE 
        WHEN cp.ClosedPostId IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus,
    pm.Rank
FROM Users u
LEFT JOIN UserBadgeCount ub ON u.Id = ub.UserId
LEFT JOIN PostMetrics pm ON u.Id = pm.OwnerUserId
LEFT JOIN ClosedPosts cp ON pm.PostId = cp.ClosedPostId
WHERE u.Reputation > 1000 
    AND pm.Rank <= 10
ORDER BY pm.Rank, u.DisplayName;

