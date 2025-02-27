
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Score, 
        p.ViewCount, 
        p.CreationDate, 
        p.LastActivityDate, 
        p.OwnerUserId, 
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
), UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.Reputation, 
        COUNT(ph.Id) AS EditCount
    FROM 
        Users u 
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id 
    GROUP BY 
        u.Id, u.Reputation
), PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', numbers.n), ',', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= numbers.n - 1
    WHERE 
        Tags IS NOT NULL
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
)
SELECT 
    rp.PostId, 
    rp.Title, 
    rp.Score, 
    rp.ViewCount, 
    ur.Reputation, 
    ur.EditCount, 
    pt.TagName AS PopularTag
FROM 
    RankedPosts rp
JOIN 
    UserReputation ur ON rp.OwnerUserId = ur.UserId
CROSS JOIN 
    PopularTags pt
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.Score DESC, 
    rp.ViewCount DESC;
