WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, '><')) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    p.PostId,
    p.Title,
    p.CreationDate,
    p.Score,
    p.AnswerCount,
    p.ViewCount,
    ub.BadgeCount,
    pt.TagName
FROM 
    RankedPosts p
JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
JOIN 
    PopularTags pt ON pt.TagName = ANY(string_to_array(p.Tags, '><'))
WHERE 
    p.Rank <= 3
ORDER BY 
    p.Score DESC, p.ViewCount DESC;
