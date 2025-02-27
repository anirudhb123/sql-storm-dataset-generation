
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, COUNT(c.Id) DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH 
        AND p.PostTypeId = 1
    GROUP BY 
        p.Id, p.Title, p.Score
), 
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Score,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 10
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    (SELECT GROUP_CONCAT(t.TagName SEPARATOR ', ') 
     FROM Tags t 
     JOIN Posts p ON p.Id = t.ExcerptPostId 
     WHERE p.Id = tp.PostId) AS Tags,
    (SELECT COUNT(DISTINCT bh.UserId) 
     FROM PostHistory bh 
     WHERE bh.PostId = tp.PostId 
       AND bh.PostHistoryTypeId IN (10, 11) 
       AND bh.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 1 MONTH) AS CloseVoteCount
FROM 
    TopPosts tp 
ORDER BY 
    tp.Score DESC, tp.CommentCount DESC;
