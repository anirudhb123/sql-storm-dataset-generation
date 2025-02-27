WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1  -- Only considering questions
        AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Filter for the last year
),
TagAnalytics AS (
    SELECT 
        TRIM(SUBSTRING(tag, 2, LENGTH(tag)-2)) AS TagName,  -- Extracting tag from the format <tag>
        COUNT(*) AS PostCount,
        COUNT(DISTINCT OwnerDisplayName) AS UniqueAuthors
    FROM 
        RankedPosts
    CROSS JOIN 
        UNNEST(string_to_array(Tags, '><')) AS tag  -- Splitting tags
    WHERE 
        TagRank <= 5  -- Considering top 5 recent posts per tag
    GROUP BY 
        TagName
),
MostActiveTags AS (
    SELECT 
        TagName,
        PostCount,
        UniqueAuthors,
        ROW_NUMBER() OVER (ORDER BY PostCount DESC) AS TagRank
    FROM 
        TagAnalytics
)
SELECT 
    TagName,
    PostCount,
    UniqueAuthors,
    TagRank
FROM 
    MostActiveTags
WHERE 
    TagRank <= 10;  -- Top 10 most active tags
