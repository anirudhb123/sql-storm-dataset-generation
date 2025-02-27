WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year' -- Questions from the last year
),
TagUsage AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        PostId
    FROM 
        Posts
    WHERE 
        PostTypeId = 1
),
UserBadges AS (
    SELECT 
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.DisplayName
),
TopTags AS (
    SELECT 
        TagName,
        COUNT(*) AS UsageCount
    FROM 
        TagUsage
    GROUP BY 
        TagName
    ORDER BY 
        UsageCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.Score,
    ub.BadgeCount,
    ub.Badges,
    tt.TagName AS TopTag,
    tt.UsageCount
FROM 
    RankedPosts rp
JOIN 
    UserBadges ub ON rp.OwnerDisplayName = ub.DisplayName
LEFT JOIN 
    TopTags tt ON tt.TagName = ANY(STRING_TO_ARRAY((SELECT Tags FROM Posts WHERE Id = rp.PostId), '><'))
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
