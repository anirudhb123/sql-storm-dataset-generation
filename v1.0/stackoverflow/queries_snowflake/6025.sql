
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01') 
        AND p.PostTypeId = 1
),
PopularTags AS (
    SELECT 
        TRIM(value) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p,
        LATERAL FLATTEN(input => SPLIT(p.Tags, ',')) AS t
    WHERE 
        p.CreationDate >= DATEADD(year, -1, '2024-10-01')
    GROUP BY 
        TRIM(value)
    ORDER BY 
        TagCount DESC
    LIMIT 5
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.OwnerDisplayName,
    rp.AnswerCount,
    pt.TagName,
    pt.TagCount
FROM 
    RankedPosts rp
JOIN 
    Posts p ON rp.PostId = p.Id
JOIN 
    PopularTags pt ON pt.TagName IN (SELECT TRIM(value) FROM LATERAL FLATTEN(input => SPLIT(p.Tags, ',')))
WHERE 
    rp.Rank <= 3
ORDER BY 
    rp.OwnerUserId, rp.Score DESC;
