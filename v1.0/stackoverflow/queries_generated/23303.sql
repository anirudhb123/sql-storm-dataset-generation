WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        COALESCE(SUM(v.VoteTypeId = 2) OVER (PARTITION BY p.Id), 0) AS UpVotes,
        COALESCE(SUM(v.VoteTypeId = 3) OVER (PARTITION BY p.Id), 0) AS DownVotes,
        RANK() OVER (ORDER BY COALESCE(SUM(v.VoteTypeId = 2), 0) - COALESCE(SUM(v.VoteTypeId = 3), 0) DESC) AS VoteRank
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.Id
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.ViewCount,
        rp.UpVotes,
        rp.DownVotes,
        CASE 
            WHEN rp.UpVotes > rp.DownVotes THEN 'Positive' 
            WHEN rp.UpVotes < rp.DownVotes THEN 'Negative' 
            ELSE 'Neutral' 
        END AS Sentiment
    FROM RankedPosts rp
    WHERE rp.VoteRank <= 10
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostBadges AS (
    SELECT 
        p.Id AS PostId,
        COUNT(b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id
)

SELECT 
    tp.Title,
    tp.ViewCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.Sentiment,
    ub.BadgeCount AS UserBadgeCount,
    ub.BadgeNames,
    pb.BadgeCount AS PostBadgeCount,
    (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount
FROM TopPosts tp
LEFT JOIN UserBadges ub ON tp.PostId IN (
    SELECT p.Id 
    FROM Posts p 
    WHERE p.OwnerUserId = ub.UserId
)
LEFT JOIN PostBadges pb ON tp.PostId = pb.PostId
WHERE (ub.BadgeCount IS NULL OR ub.BadgeCount > 0)
ORDER BY tp.UpVotes DESC, tp.ViewCount DESC
LIMIT 5;

This SQL query extracts top posts from the last year, ranking them by upvotes and downvotes while analyzing sentiments as "Positive", "Negative", or "Neutral". It combines multiple CTEs to associate users' badge counts with posts, showcasing relationships and filtering based on badge counts. The outer joins ensure comprehensive visibility of associations, including cases for users without badges, while the final selection prioritizes engaging posts based on community interaction.
