WITH RecursiveTags AS (
    -- Step 1: Generate a list of tags for questions with their respective counts
    SELECT 
        p.Id AS PostId, 
        string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><') AS TagsArray
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only questions
), UnnestTags AS (
    -- Step 2: Unnest the array of tags into individual rows
    SELECT 
        PostId, 
        unnest(TagsArray) AS Tag
    FROM 
        RecursiveTags
), TagCounts AS (
    -- Step 3: Count the occurrences of each tag across all questions
    SELECT 
        Tag, 
        COUNT(PostId) AS TagCount
    FROM 
        UnnestTags
    GROUP BY 
        Tag
), TopTags AS (
    -- Step 4: Get the top 10 tags by count
    SELECT 
        Tag, 
        TagCount
    FROM 
        TagCounts
    ORDER BY 
        TagCount DESC
    LIMIT 10
), PostsWithTopTags AS (
    -- Step 5: Select posts that contain top tags
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
-- Final Step: Return the results with additional string processing for body summaries
SELECT 
    PostId, 
    Title, 
    CreationDate, 
    Tag,
    LEFT(Body, 150) || '...' AS BodySnippet  -- Create a snippet of the body
FROM 
    PostsWithTopTags
ORDER BY 
    CreationDate DESC;
