WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.Views,
        p.Tags,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '1 year'
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.Views,
        rp.Tags,
        rp.OwnerDisplayName,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 10 AND 
        rp.Score > 0 -- Only include posts with positive scores
),
TagStats AS (
    SELECT 
        unnest(string_to_array(LEFT(rp.Tags, LENGTH(rp.Tags) - 1), '>')) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts rp
    GROUP BY 
        TagName
)
SELECT 
    fs.PostId,
    fs.Title,
    fs.Views,
    fs.OwnerDisplayName,
    ts.TagName,
    ts.PostCount
FROM 
    FilteredPosts fs
LEFT JOIN 
    TagStats ts ON ts.TagName = ANY(string_to_array(fs.Tags, '>'))
ORDER BY 
    fs.Views DESC, 
    fs.Score DESC;

This query accomplishes the following:
- It ranks the posts created in the last year by creation date, filtering to include only the top 10 recent posts per post type (questions, answers, etc.) that have a positive score.
- It calculates statistics on the tags used in these posts using a subquery that counts the number of posts per unique tag.
- Finally, it selects relevant details including the post ID, title, view count, owner's display name, associated tags, and the number of posts associated with each tag, ordering the results primarily by view count and secondarily by score.
