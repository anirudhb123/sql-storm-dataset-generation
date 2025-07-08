
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
        p.PostTypeId = 1  
        AND p.CreationDate >= '2024-10-01 12:34:56'::timestamp - INTERVAL '1 year'
),
TagAnalytics AS (
    SELECT 
        TRIM(SUBSTRING(tag, 2, LENGTH(tag) - 2)) AS TagName,  
        COUNT(*) AS PostCount,
        COUNT(DISTINCT OwnerDisplayName) AS UniqueAuthors
    FROM 
        RankedPosts,
        LATERAL FLATTEN(input => SPLIT(Tags, '><')) AS tag  
    WHERE 
        TagRank <= 5  
    GROUP BY 
        TRIM(SUBSTRING(tag, 2, LENGTH(tag) - 2)), 
        tag, 
        OwnerDisplayName
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
    TagRank <= 10;
