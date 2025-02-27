
WITH PostDetails AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1 AS TagCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(pa.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts pa ON p.Id = pa.ParentId AND pa.PostTypeId = 1  
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
),
PopularTags AS (
    SELECT 
        tag,
        COUNT(*) AS TagFrequency
    FROM (
        SELECT 
            SUBSTRING_INDEX(SUBSTRING_INDEX(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><', numbers.n), '><', -1) AS tag
        FROM 
            Posts
        INNER JOIN 
        (
            SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
            UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
        ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) + 1 >= numbers.n
        WHERE 
            PostTypeId = 1  
    ) AS TagList
    GROUP BY 
        tag
    ORDER BY 
        TagFrequency DESC
    LIMIT 10  
),
BenchmarkData AS (
    SELECT 
        pd.PostId,
        pd.Title,
        pd.Body,
        pd.Author,
        pd.CreationDate,
        pd.Score,
        pd.ViewCount,
        pd.TagCount,
        pd.CommentCount,
        pd.AnswerCount,
        pt.TagFrequency
    FROM 
        PostDetails pd
    JOIN 
        PopularTags pt ON pd.Tags LIKE CONCAT('%', pt.tag, '%')
)
SELECT 
    b.*,
    CASE 
        WHEN b.TagCount > 5 THEN 'High Tag Count'
        WHEN b.AnswerCount > 10 THEN 'Highly Answered'
        ELSE 'Standard Post'
    END AS PostCategory
FROM 
    BenchmarkData b
ORDER BY 
    b.ViewCount DESC,
    b.Score DESC
LIMIT 20;
