WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS Author,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PostsWithTagCount AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.Author,
        rp.CreationDate,
        rp.Score,
        ARRAY_LENGTH(string_to_array(rp.Tags, '>'), 1) AS TagCount -- Count the number of tags
    FROM 
        RankedPosts rp
    WHERE 
        rn = 1 -- Get the latest question for each tag
),
FilteredPosts AS (
    SELECT 
        pt.PostId,
        pt.Title,
        pt.Body,
        pt.Tags,
        pt.Author,
        pt.CreationDate,
        pt.Score,
        pt.TagCount
    FROM 
        PostsWithTagCount pt
    WHERE 
        pt.TagCount > 3 -- Only include questions with more than 3 tags
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.Author,
    fp.CreationDate,
    fp.Score,
    STRING_AGG(t.TagName, ', ') AS RelatedTags
FROM 
    FilteredPosts fp
LEFT JOIN 
    Posts p ON fp.PostId = p.Id
LEFT JOIN 
    Tags t ON t.Id = ANY(string_to_array(substring(fp.Tags, 2, length(fp.Tags)-2), '><')::int[]) -- Extract tags from the string
GROUP BY 
    fp.PostId, fp.Title, fp.Body, fp.Author, fp.CreationDate, fp.Score
ORDER BY 
    fp.Score DESC, fp.CreationDate DESC;
