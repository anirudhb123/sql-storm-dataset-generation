
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS TagsList,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.ViewCount DESC) AS RankByViews
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName, p.Id AS PostId
         FROM Posts p CROSS JOIN 
              (SELECT a.N + b.N * 10 n FROM 
                  (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                   UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
                  CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                   UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
              ) n
         WHERE n.n <= LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS tag ON p.Id = tag.PostId
    LEFT JOIN 
        Tags t ON t.TagName = tag.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, u.DisplayName
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName
    FROM 
        Posts
    CROSS JOIN 
        (SELECT a.N + b.N * 10 n FROM 
            (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a
            CROSS JOIN (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
            UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
        ) n
    WHERE 
        PostTypeId = 1
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.ViewCount,
        rp.CommentCount,
        rp.TagsList,
        rp.RankByViews
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByViews <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.ViewCount,
    tp.CommentCount,
    tp.TagsList,
    pt.TagName AS PopularTag
FROM 
    TopPosts tp
LEFT JOIN 
    (SELECT 
         TagName, 
         COUNT(*) AS UsageCount 
     FROM 
         PopularTags 
     GROUP BY 
         TagName 
     HAVING 
         COUNT(*) >= 5) pt ON tp.TagsList LIKE CONCAT('%', pt.TagName, '%')
ORDER BY 
    tp.ViewCount DESC, tp.CommentCount DESC;
