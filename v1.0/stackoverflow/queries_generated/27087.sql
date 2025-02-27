WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 -- Questions only
        AND p.CreationDate >= DATEADD(month, -1, GETDATE()) -- Last month
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerDisplayName
),
TaggedPosts AS (
    SELECT 
        rp.*,
        STRING_AGG(t.TagName, ', ') AS TagsList
    FROM 
        RankedPosts rp
    CROSS JOIN 
        UNNEST(string_to_array(substring(rp.Tags, 2, length(rp.Tags)-2), '><')) AS tag
    JOIN 
        Tags t ON t.TagName = tag
    GROUP BY 
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.OwnerDisplayName
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    tp.TagsList
FROM 
    TaggedPosts tp
WHERE 
    tp.TagRank = 1  -- Only the latest post per tag
ORDER BY 
    tp.UpvoteCount DESC, tp.CommentCount DESC; -- Order by most upvoted and commented
