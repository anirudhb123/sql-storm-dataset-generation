
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
        AND p.AnswerCount > 0  
),
PopularTags AS (
    SELECT 
        tag, 
        COUNT(tag) AS TagCount
    FROM 
        (SELECT value AS tag
         FROM Posts p
         CROSS APPLY STRING_SPLIT(trim(replace(replace(p.Tags, '<>', ''), '>', '')), ' ')) AS Tags
         WHERE p.PostTypeId = 1
        ) AS Tags
    GROUP BY 
        tag
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Body,
    rp.Tags,
    rp.ViewCount,
    rp.AnswerCount,
    pt.TagCount AS Popularity
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.Tags LIKE '%' + pt.tag + '%'
WHERE 
    rp.TagRank <= 5  
ORDER BY 
    pt.TagCount DESC, rp.ViewCount DESC;
