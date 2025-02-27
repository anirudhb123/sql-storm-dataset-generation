
WITH TitleStats AS (
    SELECT 
        AVG(LEN(Title)) AS AvgTitleLength,
        MIN(LEN(Title)) AS MinTitleLength,
        MAX(LEN(Title)) AS MaxTitleLength,
        COUNT(*) AS TitleCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
BodyStats AS (
    SELECT 
        AVG(LEN(Body)) AS AvgBodyLength,
        MIN(LEN(Body)) AS MinBodyLength,
        MAX(LEN(Body)) AS MaxBodyLength,
        COUNT(*) AS BodyCount
    FROM 
        Posts
    WHERE 
        PostTypeId IN (1, 2) 
),
TagStats AS (
    SELECT 
        COUNT(DISTINCT Tags) AS DistinctTagCount,
        SUM(LEN(Tags) - LEN(REPLACE(Tags, '<', '')) / LEN('<')) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
),
CombinedStats AS (
    SELECT 
        t.AvgTitleLength, 
        t.MinTitleLength, 
        t.MaxTitleLength,
        b.AvgBodyLength, 
        b.MinBodyLength, 
        b.MaxBodyLength,
        tg.DistinctTagCount,
        tg.TagCount
    FROM 
        TitleStats t 
        CROSS JOIN BodyStats b 
        CROSS JOIN TagStats tg
)

SELECT 
    AvgTitleLength, 
    MinTitleLength, 
    MaxTitleLength, 
    AvgBodyLength, 
    MinBodyLength, 
    MaxBodyLength, 
    DistinctTagCount, 
    TagCount 
FROM 
    CombinedStats;
