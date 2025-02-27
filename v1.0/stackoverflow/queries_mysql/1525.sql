
WITH UserBadgeCounts AS (
    SELECT 
        UserId, 
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostWithDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.OwnerUserId,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        @row_num := IF(@prev_owner = p.OwnerUserId, @row_num + 1, 1) AS PostRank,
        @prev_owner := p.OwnerUserId
    FROM Posts p
    JOIN (SELECT @row_num := 0, @prev_owner := NULL) r
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY p.OwnerUserId, p.CreationDate DESC
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        OwnerDisplayName,
        CommentCount,
        PostRank,
        OwnerUserId
    FROM PostWithDetails
    WHERE PostRank = 1
)
SELECT 
    tb.OwnerDisplayName,
    COUNT(*) AS TopPostCount,
    SUM(COALESCE(ubc.GoldBadges, 0)) AS TotalGoldBadges,
    SUM(COALESCE(ubc.SilverBadges, 0)) AS TotalSilverBadges,
    SUM(COALESCE(ubc.BronzeBadges, 0)) AS TotalBronzeBadges
FROM TopPosts tb
LEFT JOIN UserBadgeCounts ubc ON tb.OwnerUserId = ubc.UserId
GROUP BY tb.OwnerDisplayName, tb.OwnerUserId
HAVING COUNT(*) > 5
ORDER BY TopPostCount DESC
LIMIT 10;
