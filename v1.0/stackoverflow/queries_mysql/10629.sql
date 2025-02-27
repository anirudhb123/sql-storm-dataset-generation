
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.PostTypeId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,  
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,  
        COUNT(c.Id) AS CommentCount,                       
        COUNT(DISTINCT ph.Id) AS RevisionCount             
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.PostTypeId
),

TopPosts AS (
    SELECT 
        ps.PostId,
        ps.PostTypeId,
        ps.UpVotes,
        ps.DownVotes,
        ps.CommentCount,
        ps.RevisionCount,
        @rank := @rank + 1 AS Rank
    FROM 
        PostStats ps, (SELECT @rank := 0) r
    WHERE 
        ps.PostTypeId IN (1, 2)  
    ORDER BY 
        ps.UpVotes DESC, ps.CommentCount DESC
)

SELECT 
    tp.PostId,
    tp.PostTypeId,
    tp.UpVotes,
    tp.DownVotes,
    tp.CommentCount,
    tp.RevisionCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10;
