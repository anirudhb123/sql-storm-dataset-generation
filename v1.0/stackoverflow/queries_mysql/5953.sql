
WITH ranked_posts AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           p.AnswerCount,
           p.CommentCount,
           u.DisplayName AS OwnerDisplayName,
           @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS Rank,
           @prev_owner := p.OwnerUserId
    FROM Posts p
    INNER JOIN Users u ON p.OwnerUserId = u.Id
    CROSS JOIN (SELECT @row_num := 0, @prev_owner := NULL) r
    WHERE p.PostTypeId = 1 
    ORDER BY p.OwnerUserId, p.Score DESC, p.CreationDate DESC
),
top_users AS (
    SELECT OwnerDisplayName,
           COUNT(*) AS PostCount,
           SUM(Score) AS TotalScore,
           SUM(ViewCount) AS TotalViews
    FROM ranked_posts
    WHERE Rank <= 5 
    GROUP BY OwnerDisplayName
),
badges_summary AS (
    SELECT u.DisplayName,
           COUNT(b.Id) AS BadgeCount,
           SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
           SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
           SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.DisplayName
)
SELECT tu.OwnerDisplayName,
       tu.PostCount,
       tu.TotalScore,
       tu.TotalViews,
       bs.BadgeCount,
       bs.GoldBadges,
       bs.SilverBadges,
       bs.BronzeBadges
FROM top_users tu
INNER JOIN badges_summary bs ON tu.OwnerDisplayName = bs.DisplayName
ORDER BY tu.TotalScore DESC, tu.PostCount DESC
LIMIT 10;
