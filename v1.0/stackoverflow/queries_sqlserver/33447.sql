
WITH UserBadges AS (
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
    WHERE p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
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
    STRING_AGG(tag.TagName, ', ') AS TagsList
FROM RankedPosts rp
LEFT JOIN (
    SELECT 
        DISTINCT Value AS TagName
    FROM STRING_SPLIT(rp.Tags, '>,<') 
) AS tag ON 1=1
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
