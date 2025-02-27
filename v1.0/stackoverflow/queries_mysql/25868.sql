
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS Owner,
        COUNT(CASE WHEN c.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN a.Id IS NOT NULL THEN 1 END) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Posts a ON a.ParentId = p.Id AND a.PostTypeId = 2
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName, p.Tags
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Owner,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.TagRank <= 5 
)
SELECT 
    f.PostId,
    f.Title,
    f.Body,
    f.CreationDate,
    f.ViewCount,
    f.Owner,
    f.CommentCount,
    f.AnswerCount,
    GROUP_CONCAT(DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(t.TagName, '<tag>', -1), '>', 1)) AS Tags
FROM 
    FilteredPosts f
LEFT JOIN 
    Posts p ON p.Id = f.PostId 
LEFT JOIN 
    (SELECT SUBSTRING(tag FROM 2 FOR LENGTH(tag) - 2) AS TagName 
     FROM (
         SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(f.Body, '<tag>', n.n), '<tag>', -1)) AS tag
         FROM (
             SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
             UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
             UNION ALL SELECT 9 UNION ALL SELECT 10
         ) n
     ) AS tags
    ) AS t ON TRUE
GROUP BY 
    f.PostId, f.Title, f.Body, f.CreationDate, f.ViewCount, f.Owner, f.CommentCount, f.AnswerCount
ORDER BY 
    f.ViewCount DESC
LIMIT 10;
