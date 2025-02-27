
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        U.DisplayName AS OwnerDisplayName,
        COUNT(S.Id) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments S ON p.Id = S.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, p.Score, p.Tags, U.DisplayName
),
FilteredTags AS (
    SELECT 
        p.PostId,
        LTRIM(RTRIM(value)) AS Tag
    FROM 
        RankedPosts p
    CROSS APPLY STRING_SPLIT(p.Tags, ',') AS value
    WHERE 
        p.RN = 1  
),
TagStats AS (
    SELECT 
        Tag,
        COUNT(DISTINCT PostId) AS PostCount
    FROM 
        FilteredTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(DISTINCT PostId) > 1  
),
TaggedQuestions AS (
    SELECT 
        rt.PostId,
        rt.Title,
        rt.ViewCount,
        rt.Score,
        tt.PostCount
    FROM 
        RankedPosts rt
    JOIN 
        FilteredTags ft ON rt.PostId = ft.PostId
    JOIN 
        TagStats tt ON ft.Tag = tt.Tag
)
SELECT 
    'Title: ' + TQ.Title + ', View Count: ' + CAST(TQ.ViewCount AS VARCHAR) + 
    ', Score: ' + CAST(TQ.Score AS VARCHAR) + 
    ', Tag Count: ' + CAST(TQ.PostCount AS VARCHAR) + ' Tags: ' + 
    STRING_AGG(DISTINCT ft.Tag, ', ') AS BenchmarkInfo
FROM 
    TaggedQuestions TQ
JOIN 
    FilteredTags ft ON TQ.PostId = ft.PostId
GROUP BY 
    TQ.PostId, TQ.Title, TQ.ViewCount, TQ.Score, TQ.PostCount
ORDER BY 
    TQ.PostCount DESC, TQ.Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
