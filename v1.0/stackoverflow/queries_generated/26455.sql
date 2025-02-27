WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.FavoriteCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.Score DESC) AS TagRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1 
      AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
MostActiveUsers AS (
    SELECT 
        UserId,
        COUNT(*) AS ActivityCount
    FROM Comments
    GROUP BY UserId
    HAVING COUNT(*) > 50
),
BadgeDistribution AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
OverallStats AS (
    SELECT 
        COUNT(*) AS TotalPosts,
        SUM(COALESCE(Score, 0)) AS TotalScore,
        SUM(COALESCE(ViewCount, 0)) AS TotalViews,
        AVG(AnswerCount) AS AvgAnswers,
        AVG(CommentCount) AS AvgComments
    FROM Posts
    WHERE PostTypeId = 1
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Tags,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    rp.FavoriteCount,
    rp.OwnerDisplayName,
    bd.GoldBadges,
    bd.SilverBadges,
    bd.BronzeBadges,
    stat.TotalPosts,
    stat.TotalScore,
    stat.TotalViews,
    stat.AvgAnswers,
    stat.AvgComments
FROM RankedPosts rp
JOIN BadgeDistribution bd ON rp.OwnerDisplayName = bd.UserId
CROSS JOIN OverallStats stat
WHERE rp.TagRank <= 3
ORDER BY rp.CreationDate DESC, rp.Score DESC
LIMIT 100;
