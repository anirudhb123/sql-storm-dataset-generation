
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS RankDate
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= CAST('2024-10-01 12:34:56' AS DATETIME) - DATEADD(YEAR, 1, 0)
),
TagPostCounts AS (
    SELECT 
        value AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><')
    WHERE 
        PostTypeId = 1
    GROUP BY 
        value
),
TopTags AS (
    SELECT 
        Tag,
        TagCount,
        ROW_NUMBER() OVER (ORDER BY TagCount DESC) AS TagRank
    FROM 
        TagPostCounts
    WHERE 
        TagCount IS NOT NULL
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.AnswerCount,
    tt.Tag,
    tt.TagCount,
    CASE 
        WHEN rp.RankScore <= 5 THEN 'Top Score'
        WHEN rp.RankDate <= 5 THEN 'Recent Activity'
        ELSE 'Other'
    END AS Category
FROM 
    RankedPosts rp
JOIN 
    TopTags tt ON rp.Title LIKE '%' + tt.Tag + '%'
WHERE 
    rp.RankScore <= 5 OR rp.RankDate <= 5
ORDER BY 
    rp.Score DESC, rp.CreationDate DESC;
