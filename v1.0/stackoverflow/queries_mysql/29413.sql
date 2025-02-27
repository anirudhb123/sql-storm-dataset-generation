
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        COALESCE(ph.Comment, 'No Comments') AS LastEditComment,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS CommentRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        p.CreationDate >= '2023-01-01'
),
TagStatistics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION 
               SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION 
               SELECT 8 UNION SELECT 9) a,
              (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION 
               SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION 
               SELECT 8 UNION SELECT 9) b) n
        ON n.n < 1 + (LENGTH(Tags) - LENGTH(REPLACE(Tags, '><', '')))
    WHERE 
        PostTypeId = 1  
    GROUP BY 
        TagName
),
TopTags AS (
    SELECT 
        TagName,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS PopularityRank
    FROM 
        TagStatistics
    WHERE 
        TagCount > 10  
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.LastEditComment,
    tt.TagName,
    tt.TagCount
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Tags LIKE CONCAT('%', tt.TagName, '%')
WHERE 
    rp.CommentRank = 1
ORDER BY 
    tt.TagCount DESC,
    rp.CreationDate DESC
LIMIT 50;
