WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        ARRAY_AGG(p.Tags) FILTER (WHERE p.Tags IS NOT NULL) AS TagList
    FROM Posts p
    GROUP BY p.Id, p.OwnerUserId, p.Title, p.Score
),
InnerJoins AS (
    SELECT 
        ub.UserId,
        ub.BadgeCount,
        tp.PostId,
        tp.Title,
        tp.Score,
        tp.TagList
    FROM UserBadges ub
    JOIN TopPosts tp ON ub.UserId = tp.OwnerUserId
    WHERE ub.BadgeCount > 0
),
VoteStats AS (
    SELECT 
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotesCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotesCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY p.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ub.BadgeCount,
    COALESCE(tp.PostId, -1) AS PostId,
    COALESCE(tp.Title, 'No Posts Yet') AS Title,
    tp.Score,
    vs.UpVotesCount,
    vs.DownVotesCount,
    CASE 
        WHEN ub.BadgeCount IS NULL THEN 'Unbadged User'
        ELSE 'Badged User'
    END AS BadgeStatus,
    CASE 
        WHEN tp.TagList IS NOT NULL THEN 'Tags Available'
        ELSE 'No Tags'
    END AS TagsStatus
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN InnerJoins tp ON u.Id = tp.UserId
LEFT JOIN VoteStats vs ON tp.PostId = vs.PostId
WHERE (u.Reputation > 100 OR ub.BadgeCount > 2)
AND (tp.Score IS NOT NULL OR (tp.Score IS NULL AND tp.PostId IS NULL))
ORDER BY u.Reputation DESC, tp.Score DESC, tp.Title
OFFSET (SELECT COUNT(*) FROM Users) / 2 ROWS 
FETCH NEXT 10 ROWS ONLY;

