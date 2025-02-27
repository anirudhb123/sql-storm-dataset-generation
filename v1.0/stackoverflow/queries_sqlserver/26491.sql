
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
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
TagStats AS (
    SELECT 
        VALUE AS TagName,
        COUNT(*) AS TotalPosts,
        SUM(Score) AS TotalScore,
        SUM(ViewCount) AS TotalViews
    FROM 
        RankedPosts 
    CROSS APPLY STRING_SPLIT(REPLACE(REPLACE(Tags, '<', ''), '>', ''), '>') 
    WHERE 
        TagRank <= 5  
    GROUP BY 
        VALUE
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
