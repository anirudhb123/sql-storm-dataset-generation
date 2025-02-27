WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        p.ViewCount,
        RANK() OVER (ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 AND p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount
),
TopPosts AS (
    SELECT 
        rp.*, 
        (UpVotes - DownVotes) AS Score
    FROM 
        RankedPosts rp
    WHERE 
        Rank <= 10
)
SELECT 
    tp.PostId, 
    tp.Title, 
    tp.CreationDate, 
    tp.CommentCount, 
    tp.UpVotes, 
    tp.DownVotes, 
    tp.ViewCount, 
    tp.Score,
    u.DisplayName AS OwnerDisplayName,
    u.Reputation AS OwnerReputation
FROM 
    TopPosts tp
    JOIN Users u ON tp.OwnerUserId = u.Id
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
