WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
        AND p.PostTypeId IN (1, 2)  -- only questions and answers
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
),
UserVotes AS (
    SELECT 
        v.UserId,
        COUNT(v.Id) AS VoteCount
    FROM 
        Votes v
    WHERE 
        v.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        v.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    uv.VoteCount
FROM 
    Users u
JOIN 
    TopPosts tp ON u.Id = tp.PostId
LEFT JOIN 
    UserVotes uv ON u.Id = uv.UserId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC, uv.VoteCount DESC;
