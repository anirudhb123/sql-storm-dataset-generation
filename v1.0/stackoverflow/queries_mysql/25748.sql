
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
        TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS Tag
    FROM 
        RankedPosts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1
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
    CONCAT('Title: ', TQ.Title, ', View Count: ', TQ.ViewCount, ', Score: ', TQ.Score, 
           ', Tag Count: ', TQ.PostCount, ' Tags: ', 
           GROUP_CONCAT(DISTINCT ft.Tag ORDER BY ft.Tag SEPARATOR ', ')) AS BenchmarkInfo
FROM 
    TaggedQuestions TQ
JOIN 
    FilteredTags ft ON TQ.PostId = ft.PostId
GROUP BY 
    TQ.PostId, TQ.Title, TQ.ViewCount, TQ.Score, TQ.PostCount
ORDER BY 
    TQ.PostCount DESC, TQ.Score DESC
LIMIT 10;
