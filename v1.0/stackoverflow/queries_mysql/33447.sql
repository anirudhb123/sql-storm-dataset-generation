
WITH RECURSIVE UserBadges AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
PostScore AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        p.Score,
        COALESCE(MAX(b.Class), 0) AS MaxBadgeClass 
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY p.Id, p.OwnerUserId, p.Score
),
PostWithUserStats AS (
    SELECT 
        p.*,
        COALESCE(u.Reputation, 0) AS UserReputation,
        COALESCE(ub.BadgeCount, 0) AS UserBadgeCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
),
RankedPosts AS (
    SELECT 
        pwus.*,
        RANK() OVER (PARTITION BY pwus.PostTypeId ORDER BY pwus.Score DESC, pwus.ViewCount DESC) AS PostRank
    FROM PostWithUserStats pwus
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserReputation,
    rp.UserBadgeCount,
    CASE 
        WHEN rp.AcceptedAnswerId IS NOT NULL THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AnswerStatus,
    GROUP_CONCAT(DISTINCT tag.TagName ORDER BY tag.TagName SEPARATOR ', ') AS TagsList
FROM RankedPosts rp
LEFT JOIN (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '>,<', numbers.n), '>,<', -1)) AS TagName
    FROM 
        (SELECT @rownum := @rownum + 1 AS n FROM 
        (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
         SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t1,
        (SELECT @rownum := 0) t2) numbers 
    WHERE CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, '>,<', '')) >= numbers.n - 1
) AS tag ON TRUE
WHERE rp.PostRank <= 10 
GROUP BY 
    rp.Id,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.UserReputation,
    rp.UserBadgeCount,
    rp.AcceptedAnswerId,
    rp.PostTypeId
ORDER BY 
    rp.PostTypeId, rp.Score DESC;
