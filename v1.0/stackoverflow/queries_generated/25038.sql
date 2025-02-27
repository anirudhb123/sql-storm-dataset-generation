WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Tags,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND p.PostTypeId = 1
    WHERE 
        p.PostTypeId = 1 -- Only questions
    GROUP BY 
        p.Id
),

FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Tags,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.AnswerCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5 -- Top 5 posts per user
),

TagStats AS (
    SELECT 
        UNNEST(string_to_array(LOWER(SUBSTRING(Tags, 2, LENGTH(Tags)-2)), '><')) ) AS TagName,
        COUNT(*) AS PostCount
    FROM 
        FilteredPosts
    GROUP BY 
        TagName
),

TopTags AS (
    SELECT 
        ts.TagName,
        ts.PostCount,
        RANK() OVER (ORDER BY ts.PostCount DESC) AS Rank
    FROM 
        TagStats ts
)

SELECT 
    tt.TagName,
    tt.PostCount,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.CommentCount,
    fp.AnswerCount
FROM 
    TopTags tt
JOIN 
    FilteredPosts fp ON fp.Tags LIKE '%' || tt.TagName || '%'
WHERE 
    tt.Rank <= 10
ORDER BY 
    tt.PostCount DESC, 
    fp.Score DESC;

This query performs string processing by extracting tags from posts, counting their occurrences amongst the top posts per user, and then selecting the posts related to the top tags. It utilizes common table expressions (CTEs) for organized and efficient data handling and string manipulation.
