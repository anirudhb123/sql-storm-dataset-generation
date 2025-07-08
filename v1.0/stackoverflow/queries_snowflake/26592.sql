
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        p.ViewCount,
        p.Score
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    WHERE 
        p.CreationDate >= TIMESTAMP '2024-10-01 12:34:56' - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, p.ViewCount, p.Score
),
TopTags AS (
    SELECT 
        TRIM(value) AS Tag
    FROM 
        RecentPosts,
        LATERAL SPLIT_TO_TABLE(Tags, '><') AS value
),
TagUsage AS (
    SELECT 
        Tag, 
        COUNT(*) AS UsageCount
    FROM 
        TopTags
    GROUP BY 
        Tag
    ORDER BY 
        UsageCount DESC
    LIMIT 10
),
TopPosts AS (
    SELECT 
        rp.*,
        tt.Tag
    FROM 
        RecentPosts rp
    JOIN 
        TagUsage tt ON POSITION(tt.Tag IN rp.Tags) > 0
    ORDER BY 
        rp.Score DESC, 
        rp.CreationDate DESC
    LIMIT 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.OwnerDisplayName,
    tp.AnswerCount,
    tp.CommentCount,
    tp.ViewCount,
    tp.Score,
    ARRAY_AGG(DISTINCT tt.Tag) AS TopTags
FROM 
    TopPosts tp 
JOIN 
    TopTags tt ON POSITION(tt.Tag IN tp.Tags) > 0
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.OwnerDisplayName, tp.AnswerCount, tp.CommentCount, tp.ViewCount, tp.Score
ORDER BY 
    tp.Score DESC;
