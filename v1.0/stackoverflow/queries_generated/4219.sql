WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC NULLS LAST) AS RankScore,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate,
        ph.UserDisplayName,
        ph.Comment
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.RankScore,
        us.DisplayName,
        us.Reputation,
        rp.CommentCount
    FROM RankedPosts rp
    JOIN UserStats us ON rp.OwnerUserId = us.UserId
    WHERE rp.RankScore <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.CommentCount,
    us.DisplayName AS Author,
    us.Reputation AS AuthorReputation,
    cp.Title AS ClosedPostTitle,
    cp.CreationDate AS ClosedDate,
    cp.UserDisplayName AS ClosedBy,
    cp.Comment AS ClosureReason
FROM TopPosts tp
LEFT JOIN ClosedPosts cp ON tp.Id = cp.Id
ORDER BY tp.Score DESC, tp.CommentCount DESC;
