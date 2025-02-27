WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Considering only Questions
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM RankedPosts
    GROUP BY TagName
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    rp.Tags,
    tc.TagName,
    tc.TagCount,
    ub.BadgeCount,
    ub.BadgeNames
FROM RankedPosts rp
JOIN TagCounts tc ON rp.PostId = tc.TagName::int  -- Assuming PostId is passed as tag for clarity
JOIN UserBadges ub ON rp.OwnerUserId = ub.UserId
WHERE rp.PostRank <= 5  -- Getting the latest 5 posts per user
ORDER BY rp.CreationDate DESC, ub.BadgeCount DESC;
