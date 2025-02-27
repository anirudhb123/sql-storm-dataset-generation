
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(DISTINCT LTRIM(RTRIM(tag))) AS TagCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><') AS tag
    WHERE 
        p.PostTypeId = 1  
        AND p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')  
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),

TopQuestions AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        TagCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10  
),

TagSummary AS (
    SELECT
        LTRIM(RTRIM(tag)) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        Posts
    CROSS APPLY 
        STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS tag
    GROUP BY 
        LTRIM(RTRIM(tag))
)

SELECT 
    tq.PostId,
    tq.Title,
    tq.CreationDate,
    tq.Score,
    tq.ViewCount,
    tq.OwnerDisplayName,
    tq.TagCount,
    ts.TagName,
    ts.PostCount
FROM 
    TopQuestions tq
LEFT JOIN 
    TagSummary ts ON ts.PostCount > 5  
ORDER BY 
    tq.Score DESC, tq.ViewCount DESC;
