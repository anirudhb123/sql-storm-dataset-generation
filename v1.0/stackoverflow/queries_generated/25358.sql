WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY ARRAY(SELECT DISTINCT TRIM(UNNEST(string_to_array(p.Tags, '>'))) WHERE TRIM(UNNEST(string_to_array(p.Tags, '>'))) IS NOT NULL) ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
    AND 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
PopularTags AS (
    SELECT 
        TRIM(UNNEST(string_to_array(Tags, '>'))) AS TagName, 
        COUNT(*) AS TagCount
    FROM 
        RankedPosts
    GROUP BY 
        TRIM(UNNEST(string_to_array(Tags, '>')))
    ORDER BY 
        TagCount DESC
    LIMIT 10
),
PostDetails AS (
    SELECT 
        rp.PostID,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        pt.Name AS PostTypeName
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostTypeId = pt.Id
    WHERE 
        rp.TagRank <= 5
)
SELECT 
    pd.Title,
    pd.CreationDate,
    pd.Score,
    pd.ViewCount,
    pt.TagName
FROM 
    PostDetails pd
JOIN 
    PopularTags pt ON pd.Tags ILIKE '%' || pt.TagName || '%'
ORDER BY 
    pt.TagCount DESC, pd.Score DESC
LIMIT 50;

This query analyzes the most popular tags from questions posted within the last year, ranks these questions based on their creation date, and selects top questions based on score and view counts associated with these popular tags, providing insights into active discussions on the platform.
