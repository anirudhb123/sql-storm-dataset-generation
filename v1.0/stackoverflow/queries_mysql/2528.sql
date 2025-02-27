
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR)
    GROUP BY p.Id, p.OwnerUserId
),
RankedPosts AS (
    SELECT 
        ps.PostId,
        ps.OwnerUserId,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        @rownum := IF(@prev_owner = ps.OwnerUserId, @rownum + 1, 1) AS PostRank,
        @prev_owner := ps.OwnerUserId
    FROM PostStatistics ps, (SELECT @rownum := 0, @prev_owner := NULL) r
    ORDER BY ps.OwnerUserId, ps.UpVotes DESC, ps.CommentCount DESC
)
SELECT 
    u.DisplayName,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    rp.PostId,
    rp.CommentCount,
    rp.UpVotes,
    rp.DownVotes
FROM RankedPosts rp
JOIN Users u ON rp.OwnerUserId = u.Id
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
WHERE rp.PostRank = 1
ORDER BY u.Reputation DESC
LIMIT 10;
