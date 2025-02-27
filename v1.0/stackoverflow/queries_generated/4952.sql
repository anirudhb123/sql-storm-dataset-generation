WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COUNT(v.Id) DESC) AS UserRanked
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId 
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
    GROUP BY 
        p.Id, p.OwnerUserId
), UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Date) AS LastBadgeDate
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId 
    GROUP BY 
        u.Id
), PopularTags AS (
    SELECT 
        unnest(string_to_array(p.Tags, ',')) AS TagName,
        COUNT(p.Id) AS TagCount
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
)
SELECT 
    up.UserId,
    u.DisplayName,
    rb.VoteCount,
    ub.BadgeCount,
    pt.TagCount,
    (CASE 
        WHEN rb.UserRanked <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END) AS UserType
FROM 
    RankedPosts rb
JOIN 
    Users u ON rb.Id = u.Id
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PopularTags pt ON true  -- This will join all tags to create a Cartesian product
WHERE 
    pt.TagCount > 10
ORDER BY 
    rb.VoteCount DESC, ub.BadgeCount DESC
LIMIT 50;
