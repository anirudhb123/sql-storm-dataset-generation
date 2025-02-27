
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR)
),
TagStats AS (
    SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', n.n), '><', -1) AS TagName,
        COUNT(*) AS TotalPosts,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts 
    JOIN 
        (SELECT a.N + b.N * 10 AS n
         FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
               SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
              (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
               SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
        ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= n.n - 1
    WHERE 
        TagRank <= 5  
    GROUP BY 
        TagName
),
FinalResult AS (
    SELECT 
        ts.TagName,
        ts.TotalPosts,
        ts.TotalScore,
        ts.TotalViews,
        CASE 
            WHEN ts.TotalPosts > 20 THEN 'Very Active'
            WHEN ts.TotalPosts BETWEEN 10 AND 20 THEN 'Moderately Active'
            ELSE 'Less Active' 
        END AS ActivityLevel
    FROM 
        TagStats ts
)
SELECT 
    TagName,
    TotalPosts,
    TotalScore,
    TotalViews,
    ActivityLevel
FROM 
    FinalResult
ORDER BY 
    TotalPosts DESC, 
    TotalScore DESC;
