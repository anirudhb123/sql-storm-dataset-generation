WITH RankedPosts AS (
    SELECT p.Id, 
           p.Title, 
           p.CreationDate, 
           p.Score, 
           p.OwnerUserId, 
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only Questions
),
UserReputation AS (
    SELECT u.Id AS UserId, 
           SUM(b.Class) AS TotalBadgePoints, 
           COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
PopularTags AS (
    SELECT unnest(string_to_array(p.Tags, '<>')) AS TagName, 
           COUNT(p.Id) AS TagCount
    FROM Posts p
    WHERE p.PostTypeId = 1
    GROUP BY TagName
    ORDER BY TagCount DESC
    LIMIT 5
),
PostMetrics AS (
    SELECT r.Title, 
           r.CreationDate, 
           r.Score, 
           u.DisplayName AS OwnerDisplayName, 
           u.Reputation AS UserReputation,
           rp.PostRank,
           pt.TagName
    FROM RankedPosts r
    JOIN Users u ON r.OwnerUserId = u.Id
    JOIN PopularTags pt ON pt.TagName = ANY (string_to_array(r.Tags, '<>'))
    WHERE r.PostRank <= 3
)
SELECT pm.Title, 
       pm.CreationDate, 
       pm.Score, 
       pm.OwnerDisplayName, 
       pm.UserReputation,
       pt.TagName
FROM PostMetrics pm
JOIN PostHistory ph ON pm.Id = ph.PostId
WHERE ph.CreationDate BETWEEN CURRENT_DATE - INTERVAL '30 days' AND CURRENT_DATE
ORDER BY pm.UserReputation DESC, pm.Score DESC;
