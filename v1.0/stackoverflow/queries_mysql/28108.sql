
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        pt.Name AS PostType,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE_SUB(CAST('2024-10-01' AS DATE), INTERVAL 1 YEAR) 
        AND p.ViewCount > 0
),

TopRankedPosts AS (
    SELECT 
        PostId,
        Title,
        Tags,
        Score,
        ViewCount,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        rn <= 10 
),

TagAnalytics AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, ',', n.n), ',', -1) AS Tag,
        COUNT(*) AS PostCount,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM 
        TopRankedPosts
    INNER JOIN (
        SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, ',', '')) >= n.n - 1
    GROUP BY 
        Tag
)

SELECT 
    t.Tag,
    t.PostCount,
    t.TotalViews,
    t.TotalScore,
    (SELECT COUNT(*) FROM Tags WHERE TagName = t.Tag) AS TagExists,
    (SELECT COUNT(*) FROM Posts p WHERE FIND_IN_SET(t.Tag, p.Tags)) AS PostsWithTag
FROM 
    TagAnalytics t
ORDER BY 
    TotalScore DESC,
    TotalViews DESC
LIMIT 20;
