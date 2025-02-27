
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PopularTags AS (
    SELECT 
        LOWER(TRIM(value)) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS value
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        LOWER(TRIM(value))
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    trp.Title,
    trp.ViewCount,
    trp.Score,
    STRING_AGG(DISTINCT pt.Name, ', ') AS PostTypes,
    STRING_AGG(DISTINCT pgt.Tag, ', ') AS PopularTags
FROM 
    TopRankedPosts trp
LEFT JOIN 
    PostTypes pt ON trp.PostId IN (SELECT p.Id FROM Posts p WHERE p.PostTypeId = pt.Id)
LEFT JOIN 
    PopularTags pgt ON pgt.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(trp.Tags, 2, LEN(trp.Tags) - 2), '><'))
GROUP BY 
    trp.PostId, trp.Title, trp.ViewCount, trp.Score
ORDER BY 
    trp.Score DESC, trp.ViewCount DESC;
