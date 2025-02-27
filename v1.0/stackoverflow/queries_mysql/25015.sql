
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RN
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1)) AS TagName
         FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
         WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag_ids ON true 
    LEFT JOIN 
        Tags t ON t.TagName = tag_ids.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, u.DisplayName
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
    fp.Title AS Post_Title,
    fp.OwnerDisplayName AS Owner,
    fp.CommentCount AS Number_of_Comments,
    fp.UpvoteCount AS Number_of_Upvotes,
    fp.DownvoteCount AS Number_of_Downvotes,
    fp.Tags AS Associated_Tags,
    ph.CreationDate AS Post_History_Date,
    pht.Name AS Post_History_Type
FROM 
    FilteredPosts fp
JOIN 
    PostHistory ph ON fp.PostId = ph.PostId
JOIN 
    PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
ORDER BY 
    fp.UpvoteCount DESC, fp.CommentCount DESC
LIMIT 10;
