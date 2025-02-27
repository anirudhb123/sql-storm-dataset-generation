
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC SEPARATOR ', ') AS TagsAggregated,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS LastClosedDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    LEFT JOIN (
        SELECT TagName 
        FROM (
            SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName 
            FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
            WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
        ) AS t
    ) AS t ON TRUE
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY p.Id, p.Score, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        MAX(b.Class) AS HighestBadgeClass
    FROM Badges b
    GROUP BY b.UserId
),
HighScoringUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        rp.PostId,
        rp.Score,
        rp.RankByScore,
        ub.TotalBadges,
        ub.HighestBadgeClass,
        CASE 
            WHEN ub.TotalBadges > 10 THEN 'Super User'
            WHEN ub.TotalBadges BETWEEN 5 AND 10 THEN 'Regular User'
            ELSE 'New User'
        END AS UserCategory
    FROM Users u
    INNER JOIN RankedPosts rp ON u.Id = rp.OwnerUserId
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    WHERE rp.RankByScore = 1 
      AND (rp.LastClosedDate IS NULL OR rp.LastClosedDate < NOW() - INTERVAL 30 DAY)
)
SELECT 
    hsu.UserId,
    hsu.DisplayName,
    hsu.Reputation,
    hsu.UserCategory,
    hsu.PostId,
    hsu.Score,
    hsu.TotalBadges AS UserBadges,
    hsu.HighestBadgeClass,
    CASE 
        WHEN hsu.HighestBadgeClass IS NULL THEN 'No badges earned'
        WHEN hsu.HighestBadgeClass = 1 THEN 'Gold Badge Holder'
        WHEN hsu.HighestBadgeClass = 2 THEN 'Silver Badge Holder'
        ELSE 'Bronze Badge Holder' 
    END AS BadgeDescriptor,
    CASE 
        WHEN hsu.Reputation IS NULL THEN 'Reputation Hidden'
        ELSE 'Active User with Reputation'
    END AS UserStatus
FROM HighScoringUsers hsu
WHERE hsu.Reputation >= 100
ORDER BY hsu.Reputation DESC, hsu.Score DESC
LIMIT 10;
