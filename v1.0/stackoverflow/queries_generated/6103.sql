WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS UpvoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  -- Upvotes
    WHERE 
        p.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.CommentCount,
        rp.UpvoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.rn = 1
    ORDER BY 
        rp.Score DESC, rp.CommentCount DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    u.DisplayName AS AuthorDisplayName,
    u.Reputation AS AuthorReputation,
    COUNT(b.Id) AS BadgeCount
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId
GROUP BY 
    tp.PostId, u.Id, tp.Title, tp.Score, tp.CommentCount
ORDER BY 
    tp.Score DESC;
