
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.OwnerUserId, u.DisplayName
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        OwnerDisplayName,
        CommentCount,
        UpvoteCount
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 10
),
PostDetails AS (
    SELECT 
        tp.PostId,
        tp.Title,
        tp.Body,
        tp.CreationDate,
        tp.OwnerDisplayName,
        tp.CommentCount,
        tp.UpvoteCount,
        SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Body, '>', numbers.n), '>', -1) AS TagName
    FROM 
        TopPosts tp
    JOIN 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
         UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
    ON CHAR_LENGTH(tp.Body) - CHAR_LENGTH(REPLACE(tp.Body, '>', '')) >= numbers.n - 1
)
SELECT 
    pd.PostId,
    pd.Title,
    pd.OwnerDisplayName,
    pd.CommentCount,
    pd.UpvoteCount,
    GROUP_CONCAT(DISTINCT pd.TagName) AS Tags,
    COUNT(DISTINCT ph.Id) AS EditHistoryCount
FROM 
    PostDetails pd
LEFT JOIN 
    PostHistory ph ON pd.PostId = ph.PostId AND ph.PostHistoryTypeId IN (4, 5, 6) 
GROUP BY 
    pd.PostId, pd.Title, pd.OwnerDisplayName, pd.CommentCount, pd.UpvoteCount
ORDER BY 
    pd.UpvoteCount DESC, pd.CommentCount DESC;
