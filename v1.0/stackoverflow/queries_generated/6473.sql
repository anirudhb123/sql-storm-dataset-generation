WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        u.DisplayName AS Author,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, u.DisplayName
),
TopPosts AS (
    SELECT 
        * 
    FROM 
        RankedPosts 
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.Author,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    (tp.UpVotes - tp.DownVotes) AS NetVotes
FROM 
    TopPosts tp
JOIN 
    PostHistory ph ON tp.PostId = ph.PostId
WHERE 
    ph.PostHistoryTypeId IN (10, 11, 12) -- Post closed, reopened, deleted
    AND ph.CreationDate BETWEEN '2023-01-01' AND '2023-12-31'
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
