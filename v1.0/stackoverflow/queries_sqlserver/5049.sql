
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts AS p
    LEFT JOIN 
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN 
        Votes AS v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts AS rp
    WHERE 
        rp.Rank <= 5
)
SELECT 
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation
FROM 
    TopPosts AS tp
JOIN 
    Users AS u ON tp.PostId = u.Id
ORDER BY 
    tp.Score DESC;
