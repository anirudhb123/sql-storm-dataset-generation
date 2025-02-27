
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags)-2), '><') ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CAST(DATEADD(YEAR, -1, '2024-10-01') AS DATE)
),

TopTags AS (
    SELECT 
        value AS Tag
    FROM 
        RankedPosts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags)-2), '><')
    WHERE 
        Rank <= 10  
),

MostCommonTags AS (
    SELECT 
        Tag, 
        COUNT(*) AS TagCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
    OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY  
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CommentCount,
    mc.Tag AS CommonTag,
    mc.TagCount
FROM 
    RankedPosts rp
JOIN 
    MostCommonTags mc ON mc.Tag IN (SELECT value FROM STRING_SPLIT(SUBSTRING(rp.Tags, 2, LEN(rp.Tags)-2), '><'))
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.ViewCount DESC;
