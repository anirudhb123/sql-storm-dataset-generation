WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.PostTypeId IN (1, 2) -- Only Questions and Answers
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(pt.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts pt ON pt.Tags LIKE CONCAT('%<', t.TagName, '>%')
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(pt.Id) > 10
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    pt.TagName,
    ub.BadgeCount,
    ub.BadgeNames
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON pt.PostCount > 5 -- Join with popular tags having more than 5 posts
LEFT JOIN 
    UserBadges ub ON rp.OwnerDisplayName = ub.UserId
WHERE 
    rp.PostRank <= 10 -- Top 10 posts by score or view count
ORDER BY 
    rp.CreationDate DESC;
