WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpvoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),
TagCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS Tag,
        COUNT(*) AS TagCount
    FROM 
        Posts
    WHERE 
        PostTypeId = 1 
    GROUP BY 
        Tag
),
TopTags AS (
    SELECT 
        Tag, 
        TagCount
    FROM 
        TagCounts 
    ORDER BY 
        TagCount DESC 
    LIMIT 10
),
FilteredPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Body, 
        rp.CreationDate, 
        rp.CommentCount, 
        rp.UpvoteCount
    FROM 
        RankedPosts rp
    JOIN 
        TopTags tt ON rp.Tags LIKE '%' || tt.Tag || '%' -- Filter posts by top tags
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.CommentCount,
    fp.UpvoteCount,
    CASE 
        WHEN fp.UpvoteCount > 10 THEN 'Highly Upvoted'
        WHEN fp.UpvoteCount BETWEEN 5 AND 10 THEN 'Moderately Upvoted'
        ELSE 'Less Upvoted' 
    END AS VoteCategory,
    ARRAY(SELECT tt.Tag FROM TopTags tt WHERE fp.Title LIKE '%' || tt.Tag || '%') AS RelatedTags
FROM 
    FilteredPosts fp
ORDER BY 
    fp.UpvoteCount DESC, 
    fp.CommentCount DESC;
