WITH RecursivePostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    UNION ALL
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostStats rps ON p.ParentId = rps.PostId
),
FilteredPosts AS (
    SELECT 
        rps.PostId,
        rps.Title,
        rps.Score,
        rps.ViewCount,
        rps.AnswerCount,
        rps.CreationDate,
        rps.Level,
        ROW_NUMBER() OVER (PARTITION BY rps.Level ORDER BY rps.Score DESC, rps.ViewCount DESC) AS rn
    FROM 
        RecursivePostStats rps
    WHERE 
        rps.Score > 0
),
TopPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.Score,
        fp.ViewCount,
        fp.AnswerCount,
        fp.CreationDate,
        fp.Level
    FROM 
        FilteredPosts fp
    WHERE 
        fp.rn <= 5
)
SELECT 
    tp.Title,
    tp.Score,
    tp.ViewCount,
    tp.AnswerCount,
    tp.CreationDate,
    COUNT(DISTINCT c.Id) AS CommentCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
FROM 
    TopPosts tp
LEFT JOIN 
    Comments c ON c.PostId = tp.PostId
LEFT JOIN 
    Votes v ON v.PostId = tp.PostId
GROUP BY 
    tp.PostId, tp.Title, tp.Score, tp.ViewCount, tp.AnswerCount, tp.CreationDate
ORDER BY 
    tp.Score DESC
OPTION (MAXRECURSION 1000);
