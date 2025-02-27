WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END), 0) AS PositivePostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
), 
PopularTags AS (
    SELECT 
        TRIM(REGEXP_REPLACE(tags.TagName, '<[^>]*>', '')) AS CleanTag,
        COUNT(p.Id) AS TagPostCount
    FROM 
        Posts p
    CROSS JOIN 
        LATERAL string_to_array(p.Tags, ',') AS tags(TagName)
    GROUP BY 
        CleanTag
    HAVING 
        COUNT(p.Id) > 5
    ORDER BY 
        TagPostCount DESC
    LIMIT 10
), 
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        ARRAY_AGG(b.Name) AS BadgeNames
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
RecentUserActivity AS (
    SELECT 
        ud.UserId,
        COUNT(ph.Id) AS EditCount,
        COUNT(c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Users ud
    LEFT JOIN 
        PostHistory ph ON ud.Id = ph.UserId AND ph.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    LEFT JOIN 
        Comments c ON ud.Id = c.UserId AND c.CreationDate >= CURRENT_DATE - INTERVAL '3 months'
    GROUP BY 
        ud.UserId
)
SELECT 
    u.DisplayName AS UserName,
    ur.Reputation,
    ur.PostCount,
    ur.PositivePostCount,
    pab.TagPostCount, 
    ub.BadgeNames,
    cua.EditCount,
    cua.CommentCount,
    cua.LastEditDate
FROM 
    Users u
LEFT JOIN 
    UserReputation ur ON u.Id = ur.UserId
LEFT JOIN 
    PopularTags pab ON ur.PostCount > 10
LEFT JOIN 
    UserBadges ub ON u.Id = ub.UserId
LEFT JOIN 
    RecentUserActivity cua ON u.Id = cua.UserId
WHERE 
    ur.Reputation > 1000
    AND (cua.EditCount > 5 OR cua.CommentCount > 10)
ORDER BY 
    ur.Reputation DESC, 
    pab.TagPostCount DESC, 
    cua.LastEditDate DESC
LIMIT 50
OFFSET 0;
