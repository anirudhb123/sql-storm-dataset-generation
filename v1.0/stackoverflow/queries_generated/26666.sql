WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- UpMod (upvote)
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, u.DisplayName
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1  -- Only select the latest entry per post
        AND rp.VoteCount > 5 -- Condition to filter posts with more than 5 upvotes
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Body,
    fp.CreationDate,
    fp.OwnerDisplayName,
    fp.CommentCount,
    fp.VoteCount,
    tag.TagName AS PopularTag,
    DATEDIFF('day', fp.CreationDate, CURRENT_TIMESTAMP) AS DaysSincePosted
FROM 
    FilteredPosts fp
LEFT JOIN 
    (SELECT 
        p.Tags,
        UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS TagName
    FROM 
        Posts p 
    WHERE 
        p.Tags IS NOT NULL) AS tag ON fp.PostId = p.Id
WHERE 
    tag.TagName IN ('SQL', 'PostgreSQL', 'Database') -- Popular tags of interest
ORDER BY 
    fp.VoteCount DESC,
    fp.CreationDate DESC
LIMIT 20;
