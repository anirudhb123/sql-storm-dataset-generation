WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RankRecentPosts
    FROM Posts p
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
AggregatedUserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT b.Id) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
HighScorePosts AS (
    SELECT 
        rp.Title,
        rp.Score,
        rp.ViewCount,
        COALESCE(DATE_PART('epoch', (p.ClosedDate - p.CreationDate))/3600, 0) AS ClosedPostDurationHours
    FROM RankedPosts rp
    JOIN Posts p ON rp.PostId = p.Id
    WHERE rp.RankScore <= 10
)
SELECT 
    u.DisplayName,
    u.BadgeCount,
    u.TotalBounties,
    h.Title,
    h.Score,
    h.ViewCount,
    h.ClosedPostDurationHours
FROM AggregatedUserStats u
INNER JOIN HighScorePosts h ON u.UserId = h.OwnerUserId
WHERE u.TotalBounties > 0
ORDER BY h.Score DESC, u.BadgeCount DESC
LIMIT 50;

SELECT 
    DISTINCT t.TagName,
    COALESCE(COUNT(p.Id), 0) AS RelatedPostCount
FROM Tags t
LEFT JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
WHERE t.IsModeratorOnly = TRUE
GROUP BY t.TagName
HAVING COUNT(p.Id) > 5
ORDER BY RelatedPostCount DESC;
