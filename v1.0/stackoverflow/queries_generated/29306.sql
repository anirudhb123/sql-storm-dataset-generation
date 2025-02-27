WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        p.PostTypeId,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><') AS Tags
    FROM 
        Posts p
    WHERE 
        p.Tags IS NOT NULL
),
TagCounts AS (
    SELECT 
        unnest(pt.Tags) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        PostTags pt
    GROUP BY 
        Tag
),
HighlightedUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        ur.BadgeCount,
        COALESCE(tc.TagCount, 0) AS PopularTagCount
    FROM 
        UserReputation ur
    LEFT JOIN 
        Users u ON ur.UserId = u.Id
    LEFT JOIN 
        TagCounts tc ON u.Id = ANY(SELECT unnest(string_to_array((SELECT Tags FROM Posts WHERE OwnerUserId = u.Id AND PostTypeId = 1), '><')))
    WHERE 
        ur.Reputation > 1000
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    uh.DisplayName AS UserName,
    uh.Reputation AS UserReputation,
    uh.BadgeCount AS UserBadgeCount,
    uh.PopularTagCount 
FROM 
    RankedPosts rp
JOIN 
    HighlightedUsers uh ON rp.OwnerUserId = uh.UserId
WHERE 
    rp.rn = 1
ORDER BY 
    rp.CreationDate DESC
LIMIT 10;
