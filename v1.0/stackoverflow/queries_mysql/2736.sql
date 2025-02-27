
WITH PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        @rn := IF(@prev_id = p.Id, @rn + 1, 1) AS rn,
        @prev_id := p.Id
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    CROSS JOIN (SELECT @rn := 0, @prev_id := NULL) r
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.ViewCount,
        ps.CommentCount,
        ps.UpVotes,
        ps.DownVotes,
        DENSE_RANK() OVER (ORDER BY ps.Score DESC) AS ScoreRank
    FROM PostStatistics ps
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    tu.DisplayName AS TopUser,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges
FROM TopPosts tp
JOIN TopUsers tu ON tp.PostId = (SELECT 
                                     p.Id
                                  FROM Posts p
                                  WHERE p.OwnerUserId = tu.UserId
                                  ORDER BY p.Score DESC 
                                  LIMIT 1)
WHERE tp.ScoreRank <= 10
ORDER BY tp.Score DESC, tp.ViewCount DESC;
