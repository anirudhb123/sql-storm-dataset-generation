
WITH RecursiveTags AS (
    
    SELECT 
        p.Id AS PostId, 
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS Tag
    FROM 
        Posts p
    JOIN 
        (SELECT id FROM Posts LIMIT 1000) x
    JOIN 
        (SELECT @rownum := @rownum + 1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) t, (SELECT @rownum := 0) r) n
    ON CHAR_LENGTH(p.Tags)
       -CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1
    WHERE 
        p.PostTypeId = 1  
), UnnestTags AS (
    
    SELECT 
        PostId, 
        Tag
    FROM 
        RecursiveTags
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
    CONCAT(LEFT(Body, 150), '...') AS BodySnippet  
FROM 
    PostsWithTopTags
ORDER BY 
    CreationDate DESC;
