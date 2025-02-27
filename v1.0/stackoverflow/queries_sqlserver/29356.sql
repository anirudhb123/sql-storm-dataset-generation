
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 
        AND p.Score > 0 
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        ViewCount,
        Score,
        OwnerDisplayName
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 5 
),
ProcessedTags AS (
    SELECT 
        p.Id AS PostId,
        value AS TagName 
    FROM 
        Posts p
    CROSS APPLY STRING_SPLIT(LTRIM(RTRIM(REPLACE(REPLACE(p.Tags, '<', ''), '>', ''))), ' ') AS value
    WHERE 
        p.Tags IS NOT NULL
)
SELECT 
    t.TagName,
    COUNT(DISTINCT tp.PostId) AS QuestionCount,
    SUM(tp.ViewCount) AS TotalViews,
    AVG(tp.Score) AS AvgScore,
    STRING_AGG(tp.OwnerDisplayName, ', ') AS PostOwners
FROM 
    ProcessedTags t
JOIN 
    TopPosts tp ON t.PostId = tp.PostId
GROUP BY 
    t.TagName
ORDER BY 
    QuestionCount DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
