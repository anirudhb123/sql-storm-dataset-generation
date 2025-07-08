
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
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::TIMESTAMP)
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
        TagName, 
        COUNT(*) AS TagCount
    FROM (
        SELECT 
            TRIM(SPLIT_PART(Tags, ',', seq.n)) AS TagName
        FROM 
            Posts, TABLE(GENERATOR(ROWCOUNT => 1000)) AS seq
        WHERE 
            Tags IS NOT NULL
            AND seq.n <= LENGTH(Tags) - LENGTH(REPLACE(Tags, ',', '')) + 1
    )
    WHERE 
        TagName IS NOT NULL
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
