-- This query benchmarks string processing by calculating statistics for posts on Stack Overflow,
-- focusing on the length of titles, body texts, and the distribution of tags.

WITH TitleStats AS (
    SELECT 
        AVG(LENGTH(Title)) AS AvgTitleLength,
        MIN(LENGTH(Title)) AS MinTitleLength,
        MAX(LENGTH(Title)) AS MaxTitleLength,
        COUNT(*) AS TitleCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering Questions
),
BodyStats AS (
    SELECT 
        AVG(LENGTH(Body)) AS AvgBodyLength,
        MIN(LENGTH(Body)) AS MinBodyLength,
        MAX(LENGTH(Body)) AS MaxBodyLength,
        COUNT(*) AS BodyCount
    FROM 
        Posts
    WHERE 
        PostTypeId IN (1, 2) -- Considering both Questions and Answers
),
TagStats AS (
    SELECT 
        COUNT(DISTINCT Tags) AS DistinctTagCount,
        SUM(LENGTH(Tags) - LENGTH(REPLACE(Tags, '<', '')) / LENGTH('<')) AS TagCount
        -- Counting the number of tags by calculating the occurrences of '<' in the tags string
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 -- Only considering Questions
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
        TitleStats t, BodyStats b, TagStats tg
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

-- Additionally, we would generate a detailed output of the most common tags used in Questions.
WITH CommonTags AS (
    SELECT 
        TRIM(SPLIT_PART(tag, '>', 1)) AS Tag,
        COUNT(*) AS Frequency
    FROM (
        SELECT 
            UNNEST(string_to_array(SUBSTRING(Tags FROM 2 FOR LENGTH(Tags) - 2), '><')) AS tag
        FROM 
            Posts
        WHERE 
            PostTypeId = 1
    ) AS split_tags
    GROUP BY 
        Tag
    ORDER BY 
        Frequency DESC
    LIMIT 10
)

SELECT 
    Tag, 
    Frequency 
FROM 
    CommonTags;
