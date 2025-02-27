
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId IN (1, 2) 
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56') 
),
KeywordStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount,
        SUM(LEN(p.Body) - LEN(REPLACE(p.Body, ' ', '')) + 1) AS WordCount, 
        SUM(CASE WHEN p.Body LIKE '%interesting%' THEN 1 ELSE 0 END) AS InterestingCount 
    FROM 
        Posts p
    CROSS APPLY 
        STRING_SPLIT(p.Tags, ',') AS t(TagName)
    GROUP BY 
        p.Id
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    us.DisplayName AS OwnerDisplayName,
    ks.UniqueTagCount,
    ks.WordCount,
    ks.InterestingCount
FROM 
    RankedPosts rp
JOIN 
    Users us ON rp.OwnerUserId = us.Id
JOIN 
    KeywordStatistics ks ON rp.PostId = ks.PostId
WHERE 
    rp.Rank <= 10 
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC;
