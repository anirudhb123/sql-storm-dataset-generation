WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT ph.UserId) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Filter for posts created in the last year
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.CommentCount,
        ps.UpVotes - ps.DownVotes AS Score,  -- Calculate net score
        ps.LastEditDate
    FROM 
        PostStats ps
    ORDER BY 
        Score DESC
    LIMIT 10 -- Top 10 posts
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.Score,
    tp.LastEditDate,
    u.DisplayName AS LastEditor
FROM 
    TopPosts tp
LEFT JOIN 
    Users u ON tp.LastEditDate = (SELECT MAX(LastEditDate) FROM PostHistory WHERE PostId = tp.PostId)
ORDER BY 
    tp.Score DESC;
