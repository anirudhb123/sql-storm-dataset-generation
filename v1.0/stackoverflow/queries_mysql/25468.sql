
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
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', -1), '>', 1) ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= CURDATE() - INTERVAL 1 YEAR  
),

TopTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '>', -1)) AS Tag
    FROM 
        RankedPosts
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
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
    LIMIT 5  
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
    MostCommonTags mc ON FIND_IN_SET(mc.Tag, TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, '><', -1), '>', 1)))
WHERE 
    rp.Rank <= 10
ORDER BY 
    rp.ViewCount DESC;
