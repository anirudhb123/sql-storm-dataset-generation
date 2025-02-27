
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS TagRank,
        p.Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
TagAnalysis AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag,
        COUNT(*) AS PostCount,
        AVG(p.ViewCount) AS AverageViewCount,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) n 
        ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.Tags IS NOT NULL
    GROUP BY 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1)
)
SELECT 
    ra.OwnerDisplayName,
    ra.Title,
    ra.PostId,
    ra.CreationDate,
    ra.ViewCount,
    ra.Score,
    ta.Tag,
    ta.PostCount,
    ta.AverageViewCount,
    ta.AverageScore
FROM 
    RankedPosts ra
JOIN 
    TagAnalysis ta ON ra.Tags LIKE CONCAT('%', ta.Tag, '%')
WHERE 
    ra.TagRank <= 3 
ORDER BY 
    ta.PostCount DESC, 
    ra.ViewCount DESC;
