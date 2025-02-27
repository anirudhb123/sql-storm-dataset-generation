
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT a.Id) AS AnswerCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @row_num := @row_num + 1 AS YearlyRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    JOIN 
        (SELECT @row_num := 0) r ON 
        p.CreationDate >= '2020-01-01'
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount 
    ORDER BY 
        EXTRACT(YEAR FROM p.CreationDate), p.Score DESC, p.ViewCount DESC
),
TopPosts AS (
    SELECT 
        rp.*,
        @overall_rank := @overall_rank + 1 AS OverallRank
    FROM 
        RankedPosts rp
    JOIN 
        (SELECT @overall_rank := 0) o ON TRUE
    WHERE 
        rp.YearlyRank <= 5
)
SELECT 
    tp.Id,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.AnswerCount,
    tp.UpVotes,
    tp.DownVotes,
    tp.OverallRank
FROM 
    TopPosts tp
ORDER BY 
    tp.OverallRank;
