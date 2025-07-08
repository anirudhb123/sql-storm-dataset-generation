
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        LISTAGG(DISTINCT t.TagName, ', ') WITHIN GROUP (ORDER BY t.TagName) AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN,
        p.CreationDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        TABLE(FLATTEN(INPUT => SPLIT(SUBSTR(p.Tags, 2, LEN(p.Tags)-2), '><'))) ) AS tag_ids ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag_ids.VALUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        OwnerDisplayName, 
        CommentCount, 
        UpvoteCount, 
        DownvoteCount, 
        Tags
    FROM 
        RankedPosts
    WHERE 
        RN = 1 AND UpvoteCount > DownvoteCount
)
SELECT 
    fp.Title AS "Post Title",
    fp.OwnerDisplayName AS "Owner",
    fp.CommentCount AS "Number of Comments",
    fp.UpvoteCount AS "Number of Upvotes",
    fp.DownvoteCount AS "Number of Downvotes",
    fp.Tags AS "Associated Tags",
    ph.CreationDate AS "Post History Date",
    pht.Name AS "Post History Type"
FROM 
    FilteredPosts fp
JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY 
    fp.UpvoteCount DESC, fp.CommentCount DESC
LIMIT 10;
