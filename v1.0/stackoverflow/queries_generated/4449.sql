WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        p.OwnerDisplayName,
        COALESCE(COUNT(c.Id), 0) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    GROUP BY p.Id, p.Title, p.CreationDate, p.Score, p.AnswerCount, p.ViewCount, p.OwnerDisplayName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
AggregateStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(b.GoldBadges, 0) AS GoldBadges,
        COALESCE(b.SilverBadges, 0) AS SilverBadges,
        COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM Users u
    LEFT JOIN UserBadges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.AnswerCount,
    rp.ViewCount,
    a.DisplayName,
    a.GoldBadges,
    a.SilverBadges,
    a.BronzeBadges,
    a.TotalViews,
    a.TotalScore,
    CASE 
        WHEN rp.Rank <= 3 THEN 'Top Rank'
        WHEN rp.Rank BETWEEN 4 AND 10 THEN 'Mid Rank'
        ELSE 'Low Rank'
    END AS RankCategory
FROM RankedPosts rp
JOIN AggregateStats a ON rp.OwnerUserId = a.UserId
WHERE rp.CommentCount > 5
  AND rp.Score IS NOT NULL
  AND a.TotalViews > 100
ORDER BY rp.CreationDate DESC
LIMIT 50;
