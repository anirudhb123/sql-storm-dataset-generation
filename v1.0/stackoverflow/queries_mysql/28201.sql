
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.Tags,
        u.DisplayName AS OwnerName,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) as RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1  
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.Tags, p.CreationDate
),
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.Tags,
        rp.OwnerName,
        rp.CreationDate,
        rp.CommentCount,
        rp.Upvotes,
        rp.Downvotes,
        (rp.Upvotes - rp.Downvotes) AS NetVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum = 1  
),
TaggedPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Body,
        fp.Tags,
        fp.OwnerName,
        fp.CreationDate,
        fp.CommentCount,
        fp.Upvotes,
        fp.Downvotes,
        fp.NetVotes,
        SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Tags, ',', numbers.n), ',', -1) AS TagArray
    FROM 
        FilteredPosts fp
    JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
          UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(fp.Tags) - CHAR_LENGTH(REPLACE(fp.Tags, ',', '')) >= numbers.n - 1
)
SELECT 
    tp.TagArray AS Tag,
    COUNT(tp.PostId) AS PostCount,
    AVG(tp.Upvotes) AS AvgUpvotes,
    AVG(tp.Downvotes) AS AvgDownvotes,
    AVG(tp.CommentCount) AS AvgComments,
    AVG(tp.NetVotes) AS AvgNetVotes
FROM 
    TaggedPosts tp
GROUP BY 
    tp.TagArray
ORDER BY 
    PostCount DESC
LIMIT 10;
