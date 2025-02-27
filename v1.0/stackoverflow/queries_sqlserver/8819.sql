
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVoteCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        p.Id, p.Title, p.ViewCount, p.CreationDate, p.Score, p.PostTypeId
),
TopPosts AS (
    SELECT 
        PostId, Title, ViewCount, CreationDate, Score, CommentCount, UpVoteCount, DownVoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 5
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    u.DisplayName AS TopUser
FROM 
    TopPosts tp
JOIN 
    Users u ON u.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
