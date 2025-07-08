
WITH RecursiveTags AS (
    
    SELECT 
        p.Id AS PostId, 
        SPLIT(REGEXP_REPLACE(p.Tags, '^\\{|\\}$', ''), '><') AS TagsArray
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  
), UnnestTags AS (
    
    SELECT 
        PostId, 
        TAG AS Tag
    FROM 
        RecursiveTags, LATERAL FLATTEN(input => TagsArray)
), TagCounts AS (
    
    SELECT 
        Tag, 
        COUNT(PostId) AS TagCount
    FROM 
        UnnestTags
    GROUP BY 
        Tag
), TopTags AS (
    
    SELECT 
        Tag, 
        TagCount
    FROM 
        TagCounts
    ORDER BY 
        TagCount DESC
    LIMIT 10
), PostsWithTopTags AS (
    
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.Body, 
        p.CreationDate, 
        tt.Tag
    FROM 
        Posts p
    JOIN 
        UnnestTags ut ON p.Id = ut.PostId
    JOIN 
        TopTags tt ON ut.Tag = tt.Tag
)

SELECT 
    PostId, 
    Title, 
    CreationDate, 
    Tag,
    LEFT(Body, 150) || '...' AS BodySnippet  
FROM 
    PostsWithTopTags
ORDER BY 
    CreationDate DESC;
