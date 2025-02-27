
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 YEAR
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        Score,
        ViewCount,
        CreationDate
    FROM 
        RankedPosts
    WHERE 
        PostRank <= 5
),
PostVoteCounts AS (
    SELECT 
        PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Votes v
    GROUP BY 
        PostId
),
PostCommentCounts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.ViewCount,
    tp.CreationDate,
    IFNULL(pv.UpvoteCount, 0) AS UpvoteCount,
    IFNULL(pv.DownvoteCount, 0) AS DownvoteCount,
    IFNULL(pc.CommentCount, 0) AS CommentCount
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteCounts pv ON tp.PostId = pv.PostId
LEFT JOIN 
    PostCommentCounts pc ON tp.PostId = pc.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
