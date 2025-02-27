WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 AND -- Only questions
        p.CreationDate >= NOW() - INTERVAL '1 year' -- Asked within the last year
),
TopPosts AS (
    SELECT 
        rp.PostId, 
        rp.Title, 
        rp.Score, 
        rp.ViewCount,
        COALESCE(u.DisplayName, 'Deleted User') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5 -- Top 5 questions per user
),
PostVoteStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
),
PostComments AS (
    SELECT 
        c.PostId,
        COUNT(c.Id) AS CommentCount
    FROM 
        Comments c
    GROUP BY 
        c.PostId
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    pvs.Upvotes,
    pvs.Downvotes,
    COALESCE(pc.CommentCount, 0) AS CommentCount,
    CASE 
        WHEN tp.Score > 50 THEN 'Hot'
        WHEN tp.Score BETWEEN 20 AND 50 THEN 'Popular'
        ELSE 'New'
    END AS Popularity
FROM 
    TopPosts tp
LEFT JOIN 
    PostVoteStats pvs ON tp.PostId = pvs.PostId
LEFT JOIN 
    PostComments pc ON tp.PostId = pc.PostId
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
