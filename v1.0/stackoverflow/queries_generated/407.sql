WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID, 
        p.Title, 
        p.CreationDate, 
        p.Score, 
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS UserPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND p.Score > 0
),
UserReputation AS (
    SELECT 
        u.Id AS UserID, 
        u.Reputation, 
        COUNT(DISTINCT p.Id) AS PostCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
PopularTags AS (
    SELECT 
        UNNEST(string_to_array(p.Tags, '>')) AS TagName, 
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
    up.UserDisplayName, 
    up.Reputation, 
    up.PostCount, 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    rp.ViewCount, 
    pt.TagName
FROM 
    UserReputation up
JOIN 
    RankedPosts rp ON up.UserID = rp.PostID
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' || pt.TagName || '%'
WHERE 
    up.Reputation > 1000
    AND rp.UserPostRank = 1
ORDER BY 
    up.Reputation DESC, 
    rp.Score DESC
LIMIT 10;
