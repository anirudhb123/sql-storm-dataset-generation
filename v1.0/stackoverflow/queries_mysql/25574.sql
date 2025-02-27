
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
        (SELECT TRIM(BOTH '<>' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '> <', numbers.n), '> <', -1)) AS tag
         FROM Posts p
         INNER JOIN (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5
                     UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '> <', '')) >= numbers.n - 1
         WHERE p.PostTypeId = 1) AS Tags
    GROUP BY 
        tag
    ORDER BY 
        TagCount DESC
    LIMIT 10  
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
    PopularTags pt ON rp.Tags LIKE CONCAT('%', pt.tag, '%')
WHERE 
    rp.TagRank <= 5  
ORDER BY 
    pt.TagCount DESC, rp.ViewCount DESC;
