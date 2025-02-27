
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerUser,
        ROW_NUMBER() OVER (PARTITION BY YEAR(p.CreationDate) ORDER BY p.ViewCount DESC) AS RankYearly
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATEADD(YEAR, -5, '2024-10-01')
),
PopularTags AS (
    SELECT 
        value AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') 
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        value
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.OwnerUser,
    pt.TagName,
    ast.AnswerCount AS RelatedAnswerCount,
    rp.RankYearly
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.ViewCount > 100 
LEFT JOIN 
    AnswerStats ast ON rp.PostId = ast.PostId
WHERE 
    rp.RankYearly <= 3 
ORDER BY 
    rp.CreationDate DESC, rp.ViewCount DESC;
