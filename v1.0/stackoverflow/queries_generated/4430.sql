WITH RankedPosts AS (
    SELECT 
        p.Id, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn,
        COUNT(*) OVER (PARTITION BY p.OwnerUserId) AS TotalPosts
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.OwnerUserId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.TotalPosts
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn <= 3
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularTags AS (
    SELECT 
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS Tag
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 10
)
SELECT 
    u.DisplayName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    ub.BadgeCount,
    pt.Tag
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    PopularTags pt ON pt.Tag = ANY(string_to_array(substring(tp.Title, 2, length(tp.Title)-2), ' '))  -- Assuming Title contains tags
WHERE 
    tp.Score >= 1 
AND 
    tp.TotalPosts > 5
ORDER BY 
    tp.Score DESC, 
    tp.CreationDate DESC;
