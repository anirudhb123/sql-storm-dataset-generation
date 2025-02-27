WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
),
TopPosts AS (
    SELECT 
        r.PostId,
        r.Title,
        r.CreationDate,
        r.Score,
        r.ViewCount,
        r.CommentCount,
        r.VoteCount
    FROM 
        RankedPosts r
    WHERE 
        r.Rank <= 10  -- Top 10 posts per type
)
SELECT 
    u.DisplayName AS Author,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    CASE 
        WHEN tp.Score >= 100 THEN 'Hot Topic'
        ELSE 'Regular Topic'
    END AS TopicStatus
FROM 
    TopPosts tp
JOIN 
    Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.Score DESC, 
    tp.ViewCount DESC;
