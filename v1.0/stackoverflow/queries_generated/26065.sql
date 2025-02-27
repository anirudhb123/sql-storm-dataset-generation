WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.PostTypeId = 1  -- Considering only questions
        AND p.ClosedDate IS NULL  -- Excluding closed questions
),

TagsStatistics AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount,
        SUM(pt.ViewCount) AS TotalViews
    FROM Tags t
    JOIN Posts pt ON pt.Tags LIKE '%' || t.TagName || '%'  -- Matching posts that use the tag
    WHERE pt.PostTypeId = 1  -- Only questions
    GROUP BY t.TagName
),

UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgesList
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    ts.TagName,
    ts.PostCount,
    ts.TotalViews,
    ub.BadgeCount,
    ub.BadgesList
FROM RankedPosts rp
JOIN TagsStatistics ts ON ts.PostCount > 0  -- Only including tags with associated posts
JOIN UserBadges ub ON rp.OwnerDisplayName = ub.UserId
WHERE rp.PostRank <= 5  -- Get latest 5 posts by each user
ORDER BY rp.CreationDate DESC, rp.Score DESC;
