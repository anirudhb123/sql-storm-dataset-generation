WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        u.DisplayName AS OwnerName,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        rp.*, 
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpvoteCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 3
),
PostHistorySummary AS (
    SELECT 
        ph.PostId,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate AS PostCreationDate,
    tp.OwnerName,
    tp.Score,
    tp.ViewCount,
    tp.UpvoteCount,
    tp.DownvoteCount,
    coalesce(phe.EditCount, 0) AS TotalEditCount,
    phe.LastEditDate
FROM 
    TopPosts tp
LEFT JOIN 
    PostHistorySummary phe ON tp.PostId = phe.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC
LIMIT 10;

-- This query retrieves the top-ranked posts over the past year by their scores, along with their 
-- respective upvote and downvote counts. It also includes a summary of how many edits 
-- have been made to each of those posts.
