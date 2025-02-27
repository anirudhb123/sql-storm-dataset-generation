
WITH UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(CASE WHEN ub.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN ub.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN ub.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges ub
    GROUP BY ub.UserId
),
TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        @row_number:=IF(@prev_reputation = u.Reputation, @row_number + 1, 1) AS Rank,
        @prev_reputation := u.Reputation
    FROM Users u, (SELECT @row_number := 0, @prev_reputation := NULL) AS vars
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    ORDER BY u.Reputation DESC
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        @user_post_rank:=IF(@prev_user_id = p.OwnerUserId, @user_post_rank + 1, 1) AS UserPostRank,
        @prev_user_id := p.OwnerUserId
    FROM Posts p, (SELECT @user_post_rank := 0, @prev_user_id := NULL) AS user_vars
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= UNIX_TIMESTAMP('2024-10-01 12:34:56') - INTERVAL 30 DAY 
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score
    ORDER BY p.CreationDate DESC
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.OwnerUserId,
        rp.Score,
        rp.CommentCount,
        u.DisplayName AS OwnerName,
        @post_rank:=IF(@prev_score = rp.Score, @post_rank + 1, 1) AS PostRank,
        @prev_score := rp.Score
    FROM RecentPosts rp, (SELECT @post_rank := 0, @prev_score := NULL) AS post_vars
    JOIN Users u ON rp.OwnerUserId = u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.GoldBadges,
    tu.SilverBadges,
    tu.BronzeBadges,
    tp.PostId,
    tp.Title AS PostTitle,
    tp.CreationDate AS PostCreationDate,
    tp.Score AS PostScore,
    tp.CommentCount AS PostCommentCount
FROM TopUsers tu
LEFT JOIN TopPosts tp ON tu.UserId = tp.OwnerUserId
WHERE tu.Rank <= 10 AND (tp.PostRank IS NULL OR tp.PostRank <= 5)
ORDER BY tu.Reputation DESC, tp.Score DESC;
