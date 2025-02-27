WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
      AND p.Score > 0
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM Posts p
    WHERE p.PostTypeId = 1
      AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY TagName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(*) AS BadgeCount
    FROM Badges b
    WHERE b.Date >= NOW() - INTERVAL '1 year'
    GROUP BY b.UserId
),
FinalReport AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.OwnerDisplayName,
        t.TagName,
        u.BadgeCount
    FROM RankedPosts r
    LEFT JOIN PopularTags t ON r.PostId IN (SELECT p.Id FROM Posts p WHERE p.Tags LIKE '%' || t.TagName || '%')
    LEFT JOIN UserBadges u ON r.OwnerUserId = u.UserId
)
SELECT 
    f.PostId,
    f.Title,
    f.CreationDate,
    f.Score,
    f.ViewCount,
    f.OwnerDisplayName,
    f.TagName,
    COALESCE(f.BadgeCount, 0) AS BadgeCount
FROM FinalReport f
WHERE f.Rank <= 5
ORDER BY f.Score DESC, f.ViewCount DESC;
