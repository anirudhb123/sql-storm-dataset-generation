
WITH PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COUNT(co.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        p.Score,
        p.ViewCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments co ON p.Id = co.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= '2023-01-01' 
        AND p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        CommentCount,
        UpVoteCount,
        DownVoteCount,
        Score,
        ViewCount,
        @rank := IF(@prevScore = Score, @rank, @rank + 1) AS Rank,
        @prevScore := Score
    FROM 
        PostStatistics, (SELECT @rank := 0, @prevScore := NULL) AS vars
    ORDER BY 
        Score DESC, UpVoteCount DESC, CreationDate DESC
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.Score,
    tp.ViewCount
FROM 
    TopPosts tp
WHERE 
    tp.Rank <= 10
ORDER BY 
    tp.Rank;
