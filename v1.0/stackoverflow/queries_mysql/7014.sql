
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVoteCount,
        ps.DownVoteCount,
        ps.AcceptedCount,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats ps
    CROSS JOIN (SELECT @rank := 0) r
    ORDER BY ps.UpVoteCount - ps.DownVoteCount DESC, ps.AcceptedCount DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.AcceptedCount,
    (SELECT GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
     FROM Tags t 
     JOIN Posts p ON p.Tags LIKE CONCAT('%<', t.TagName, '>%')
     WHERE p.Id = tp.PostId) AS Tags
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
