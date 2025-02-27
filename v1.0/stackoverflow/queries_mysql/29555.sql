
WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.ViewCount,
        p.Score,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Posts a WHERE a.ParentId = p.Id) AS AnswerCount
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate > NOW() - INTERVAL 30 DAY
),
PopularTags AS (
    SELECT 
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(REPLACE(REPLACE(Tags, '<', ''), '>', ''), ' ', n.n), ' ', -1)) AS Tag
    FROM 
        RecentPosts r
    INNER JOIN 
        (SELECT a.N + b.N * 10 + 1 n
         FROM 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
              UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
         ON CHAR_LENGTH(REPLACE(REPLACE(Tags, '<', ''), '>', '')) - CHAR_LENGTH(REPLACE(REPLACE(REPLACE(Tags, '<', ''), '>', ''), ' ', '')) >= n.n - 1
),
TagAggregation AS (
    SELECT 
        Tag,
        COUNT(*) AS UsageCount
    FROM 
        PopularTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 1
),
TopTags AS (
    SELECT 
        Tag
    FROM 
        TagAggregation
    ORDER BY 
        UsageCount DESC
    LIMIT 5
),
PostWithTopTags AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.OwnerDisplayName, 
        rp.CreationDate, 
        rp.ViewCount, 
        rp.Score, 
        rp.CommentCount,
        rp.AnswerCount,
        GROUP_CONCAT(tt.Tag SEPARATOR ', ') AS TopTags
    FROM 
        RecentPosts rp
    JOIN 
        TopTags tt ON FIND_IN_SET(tt.Tag, REPLACE(REPLACE(rp.Tags, '<', ''), '>', '')) 
    GROUP BY 
        rp.PostId, rp.Title, rp.OwnerDisplayName, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.AnswerCount
)
SELECT 
    p.Title,
    p.OwnerDisplayName,
    p.CreationDate,
    p.ViewCount,
    p.Score,
    p.CommentCount,
    p.AnswerCount,
    p.TopTags
FROM 
    PostWithTopTags p
ORDER BY 
    p.Score DESC, p.ViewCount DESC
LIMIT 10;
