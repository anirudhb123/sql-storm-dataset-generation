
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        P.CreationDate,
        U.DisplayName AS Author,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        CHAR_LENGTH(P.Body) AS BodyLength
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1  
),
ProcessedTags AS (
    SELECT 
        PostId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS Tag
    FROM 
        RankedPosts
    INNER JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n-1
    WHERE 
        Tags IS NOT NULL
),
FilteredTags AS (
    SELECT 
        Tag,
        COUNT(*) AS TagUsage
    FROM 
        ProcessedTags
    GROUP BY 
        Tag
    HAVING 
        COUNT(*) > 5  
),
FinalBenchmark AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Author,
        RP.CreationDate,
        RP.BodyLength,
        FT.Tag,
        FT.TagUsage
    FROM 
        RankedPosts RP
    JOIN 
        FilteredTags FT ON RP.PostId IN (
            SELECT PostId 
            FROM ProcessedTags WHERE Tag = FT.Tag
        )
    WHERE 
        RP.PostRank = 1  
)
SELECT 
    *,
    TIMESTAMPDIFF(SECOND, CreationDate, '2024-10-01 12:34:56') AS AgeInSeconds
FROM 
    FinalBenchmark
ORDER BY 
    AgeInSeconds DESC, 
    TagUsage DESC
LIMIT 100;
