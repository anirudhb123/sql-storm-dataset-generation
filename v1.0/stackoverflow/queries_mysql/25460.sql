
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        COALESCE(a.AnswerCount, 0) AS AnswerCount,
        COALESCE(c.CommentCount, 0) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            ParentId,
            COUNT(*) AS AnswerCount
        FROM 
            Posts
        WHERE 
            PostTypeId = 2
        GROUP BY 
            ParentId
    ) a ON p.Id = a.ParentId
    LEFT JOIN (
        SELECT 
            PostId,
            COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) c ON p.Id = c.PostId
    WHERE 
        p.PostTypeId = 1
),
ExplodedTags AS (
    SELECT 
        rp.Id AS PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(rp.Tags, ',', numbers.n), ',', -1) AS Tag
    FROM 
        RankedPosts rp
    INNER JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(rp.Tags) - CHAR_LENGTH(REPLACE(rp.Tags, ',', '')) >= numbers.n - 1
    WHERE 
        rp.rn = 1
),
TagPopularity AS (
    SELECT 
        Tag,
        COUNT(PostId) AS TagCount
    FROM 
        ExplodedTags
    GROUP BY 
        Tag
    ORDER BY 
        TagCount DESC
),
TopTags AS (
    SELECT 
        Tag
    FROM 
        TagPopularity
    LIMIT 10
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    tp.Tag
FROM 
    RankedPosts rp
JOIN 
    ExplodedTags et ON rp.Id = et.PostId
JOIN 
    TopTags tp ON et.Tag = tp.Tag
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;
