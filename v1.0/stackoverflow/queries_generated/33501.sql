WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2), 0) AS UpvoteCount,
        COALESCE((SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3), 0) AS DownvoteCount,
        (SELECT COUNT(*) FROM Posts p2 WHERE p2.ParentId = p.Id) AS AnswerCount
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
),
RankedPosts AS (
    SELECT 
        pm.PostId,
        pm.Title,
        pm.CreationDate,
        pm.Score,
        pm.ViewCount,
        pm.CommentCount,
        pm.UpvoteCount,
        pm.DownvoteCount,
        CASE 
            WHEN pm.Score > 5 THEN 'High Score'
            WHEN pm.Score BETWEEN 1 AND 5 THEN 'Medium Score'
            ELSE 'Low Score'
        END AS ScoreCategory,
        RANK() OVER (ORDER BY pm.Score DESC, pm.ViewCount DESC) AS PostRank
    FROM PostMetrics pm
)
SELECT 
    u.DisplayName,
    ub.BadgeCount,
    ub.LastBadgeDate,
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.UpvoteCount,
    rp.DownvoteCount,
    rp.ScoreCategory,
    rp.PostRank
FROM Users u
JOIN UserBadges ub ON u.Id = ub.UserId
JOIN RankedPosts rp ON u.Id IN (SELECT OwnerUserId FROM Posts p WHERE p.Id = rp.PostId)
WHERE ub.BadgeCount > 0
ORDER BY rp.PostRank, u.Reputation DESC;
