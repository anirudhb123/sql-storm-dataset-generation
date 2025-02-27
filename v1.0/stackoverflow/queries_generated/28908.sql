WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag_elements ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = TRIM(tag_elements)
    WHERE 
        p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
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
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Tags,
    rp.OwnerDisplayName,
    ur.Reputation,
    ur.BadgeCount
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerDisplayName = ur.DisplayName
WHERE 
    rp.Rank = 1  -- Get the latest question per user
ORDER BY 
    ur.Reputation DESC, 
    rp.ViewCount DESC
LIMIT 10;
