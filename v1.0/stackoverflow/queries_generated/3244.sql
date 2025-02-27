WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        Score,
        ViewCount,
        CommentCount,
        UpVotes,
        DownVotes
    FROM 
        RankedPosts
    WHERE 
        rn = 1
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    CASE 
        WHEN tp.UpVotes IS NULL THEN 0 
        ELSE tp.UpVotes 
    END AS UpVotes,
    CASE 
        WHEN tp.DownVotes IS NULL THEN 0 
        ELSE tp.DownVotes 
    END AS DownVotes,
    (COALESCE(tp.UpVotes, 0) - COALESCE(tp.DownVotes, 0)) AS NetVotes,
    (SELECT COUNT(*) 
     FROM Posts p2 
     WHERE p2.OwnerUserId = tp.PostId AND p2.AcceptedAnswerId IS NOT NULL) AS AcceptedAnswerCount
FROM 
    TopPosts tp
WHERE 
    tp.Score > 0
ORDER BY 
    NetVotes DESC, tp.ViewCount DESC
LIMIT 50;
