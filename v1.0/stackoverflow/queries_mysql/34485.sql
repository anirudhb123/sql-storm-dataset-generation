
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        U.DisplayName AS Author,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.PostTypeId = 1 AND  
        p.ClosedDate IS NULL  
),
PostDetails AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Author,
        rp.Score,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Comments c ON rp.PostId = c.PostId
    LEFT JOIN 
        Votes v ON rp.PostId = v.PostId
    GROUP BY 
        rp.PostId, rp.Title, rp.CreationDate, rp.Author, rp.Score
),
TopPosts AS (
    SELECT 
        pd.*,
        RANK() OVER (ORDER BY pd.Score DESC) AS ScoreRank
    FROM 
        PostDetails pd
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Author,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
FROM 
    TopPosts tp
LEFT JOIN 
    Posts p ON tp.PostId = p.Id
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1)) AS TagName
     FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
           UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1) t ON true
WHERE 
    tp.ScoreRank <= 10  
GROUP BY 
    tp.PostId, tp.Title, tp.CreationDate, tp.Author, tp.Score, tp.CommentCount, tp.UpVotes, tp.DownVotes
ORDER BY 
    tp.Score DESC;
