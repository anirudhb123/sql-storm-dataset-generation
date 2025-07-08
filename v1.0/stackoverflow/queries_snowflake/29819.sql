
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
        ARRAY_SIZE(SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS TagCount,
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
            TRIM(value) AS tag
        FROM 
            Posts,
            LATERAL SPLIT_TO_TABLE(SUBSTR(Tags, 2, LEN(Tags) - 2), '><') AS value
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
        PopularTags pt ON pd.Tags LIKE '%' || pt.tag || '%'
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
