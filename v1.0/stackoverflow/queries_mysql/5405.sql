
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC, p.LastActivityDate DESC) AS RankByOwner
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        AnswerCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByOwner = 1
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts p
    JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)) AS TagName
         FROM Posts p
         JOIN (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
               UNION ALL SELECT 9 UNION ALL SELECT 10) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) t ON p.Id = p.Id
    GROUP BY 
        t.TagName
    ORDER BY 
        PostCount DESC 
    LIMIT 5
),
CombinedMetrics AS (
    SELECT 
        tp.Title,
        tp.CreationDate,
        tp.Score,
        tp.ViewCount,
        tp.AnswerCount,
        pt.TagName,
        pt.PostCount
    FROM 
        TopPosts tp
    CROSS JOIN 
        PopularTags pt
)
SELECT 
    cm.Title,
    cm.CreationDate,
    cm.Score,
    cm.ViewCount,
    cm.AnswerCount,
    cm.TagName,
    cm.PostCount
FROM 
    CombinedMetrics cm
ORDER BY 
    cm.Score DESC, cm.ViewCount DESC;
