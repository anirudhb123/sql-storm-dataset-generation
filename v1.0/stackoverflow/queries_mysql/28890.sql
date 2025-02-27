
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        p.Score,
        (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '><', ''))) / LENGTH('><') + 1 AS TagCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    INNER JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
        AND (p.PostTypeId = 1 OR p.PostTypeId = 2) 
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.TagCount,
        rp.RankByScore
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 10 
),
PostCommentCounts AS (
    SELECT 
        c.PostId, 
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
),
PostVoteCounts AS (
    SELECT 
        v.PostId, 
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)
SELECT 
    tp.Title,
    tp.OwnerDisplayName,
    tp.Score,
    tp.TagCount,
    COALESCE(pcc.CommentCount, 0) AS TotalComments,
    COALESCE(pvc.Upvotes, 0) AS TotalUpvotes,
    COALESCE(pvc.Downvotes, 0) AS TotalDownvotes
FROM 
    TopPosts tp
LEFT JOIN 
    PostCommentCounts pcc ON tp.PostId = pcc.PostId
LEFT JOIN 
    PostVoteCounts pvc ON tp.PostId = pvc.PostId
ORDER BY 
    tp.Score DESC, tp.Title;
