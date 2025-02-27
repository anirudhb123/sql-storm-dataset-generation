WITH UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS Upvotes,
        COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS Downvotes,
        COALESCE(SUM(b.Class = 1)::int, 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2)::int, 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3)::int, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    WHERE p.PostTypeId = 1 AND p.Score > 10
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.UserDisplayName,
        ph.CreationDate AS CloseDate,
        pt.Name AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN CloseReasonTypes pt ON ph.Comment::int = pt.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.Upvotes,
    ur.Downvotes,
    ur.GoldBadges,
    ur.SilverBadges,
    ur.BronzeBadges,
    pp.Title AS PopularPost,
    pp.Score AS PopularPostScore,
    cp.Title AS ClosedPost,
    cp.CloseDate,
    cp.CloseReason
FROM Users u
JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN PopularPosts pp ON u.Id = pp.OwnerUserId
LEFT JOIN ClosedPosts cp ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = cp.ClosedPostId)
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC, ur.Upvotes - ur.Downvotes DESC
LIMIT 50;
