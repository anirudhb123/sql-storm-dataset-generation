
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
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY 
        p.Id, p.Title, p.Body, p.Tags, p.CreationDate, u.DisplayName, p.ViewCount, p.Score
),
TopTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        RecentPosts,
        (SELECT a.N + 1 n FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a) n
    WHERE 
        n.n <= 1 + LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', ''))
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
        TagUsage tt ON rp.Tags LIKE CONCAT('%', tt.Tag, '%')
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
    GROUP_CONCAT(DISTINCT tt.Tag) AS TopTags
FROM 
    TopPosts tp 
JOIN 
    TopTags tt ON tp.Tags LIKE CONCAT('%', tt.Tag, '%')
GROUP BY 
    tp.PostId, tp.Title, tp.Body, tp.OwnerDisplayName, tp.AnswerCount, tp.CommentCount, tp.ViewCount, tp.Score
ORDER BY 
    tp.Score DESC;
