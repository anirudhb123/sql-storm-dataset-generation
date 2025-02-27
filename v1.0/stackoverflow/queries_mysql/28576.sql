
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(v.Id) DESC, COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) 
        AND p.PostTypeId IN (1, 2) 
    GROUP BY 
        p.Id, p.Title, p.Body, u.DisplayName
),
FrequentTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM 
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
             (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) n
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
        AND LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
),
PostAggregate AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount,
        COALESCE(ft.TagCount, 0) AS FrequentTagCount
    FROM 
        RankedPosts rp
    LEFT JOIN 
        FrequentTags ft ON rp.Title LIKE CONCAT('%', ft.TagName, '%')
    WHERE 
        rp.Rank <= 10
)
SELECT 
    pa.PostId,
    pa.Title,
    pa.OwnerDisplayName,
    pa.CommentCount,
    pa.VoteCount,
    pa.FrequentTagCount
FROM 
    PostAggregate pa
ORDER BY 
    pa.VoteCount DESC, pa.CommentCount DESC
LIMIT 20;
