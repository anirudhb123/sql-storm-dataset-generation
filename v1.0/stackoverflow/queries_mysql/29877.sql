
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        u.DisplayName AS OwnerUser,
        ROW_NUMBER() OVER (PARTITION BY YEAR(p.CreationDate) ORDER BY p.ViewCount DESC) AS RankYearly
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= DATE('2024-10-01') - INTERVAL 5 YEAR
),
PopularTags AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TagCount
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n
    ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        TagName
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
AnswerStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
)
SELECT 
    rp.Title,
    rp.ViewCount,
    rp.AnswerCount,
    rp.CreationDate,
    rp.OwnerUser,
    pt.TagName,
    ast.AnswerCount AS RelatedAnswerCount,
    rp.RankYearly
FROM 
    RankedPosts rp
JOIN 
    PopularTags pt ON rp.ViewCount > 100 
LEFT JOIN 
    AnswerStats ast ON rp.PostId = ast.PostId
WHERE 
    rp.RankYearly <= 3 
ORDER BY 
    rp.CreationDate DESC, rp.ViewCount DESC;
