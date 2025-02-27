WITH FilteredPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        ph.UserDisplayName AS LastEditor,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(a.Id) AS AnswerCount
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '7 days'  -- Only consider posts from the last week
        AND p.PostTypeId = 1  -- Only questions
    GROUP BY 
        p.Id, u.DisplayName, ph.UserDisplayName
),
TagCounts AS (
    SELECT 
        PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount
    FROM 
        FilteredPosts fp
    CROSS JOIN 
        UNNEST(string_to_array(fp.Tags, '>')) AS t(TagName)  -- Treat tags as an array
    GROUP BY 
        PostId
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.OwnerDisplayName,
    fp.LastEditor,
    fp.LastEditDate,
    fp.CommentCount,
    fc.UniqueTagCount,
    fp.AnswerCount
FROM 
    FilteredPosts fp
LEFT JOIN 
    TagCounts fc ON fp.PostId = fc.PostId
ORDER BY 
    fp.CreationDate DESC;  -- Order by latest creation date
