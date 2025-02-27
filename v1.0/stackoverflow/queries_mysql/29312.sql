
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(a.Id) AS AnswerCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Posts a ON p.Id = a.ParentId AND a.PostTypeId = 2
    LEFT JOIN 
        (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
         FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
               UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
               UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
         INNER JOIN Posts p ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
    LEFT JOIN 
        Tags t ON tag = t.TagName
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score
),

TopPosts AS (
    SELECT 
        PostId,
        Title,
        CreationDate,
        ViewCount,
        Score,
        AnswerCount,
        Tags
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
),

UserVotes AS (
    SELECT 
        v.PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes v
    GROUP BY 
        v.PostId
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.AnswerCount,
    tp.Tags,
    COALESCE(uv.UpVotes, 0) AS TotalUpVotes,
    COALESCE(uv.DownVotes, 0) AS TotalDownVotes,
    (COALESCE(uv.UpVotes, 0) - COALESCE(uv.DownVotes, 0)) AS NetVotes
FROM 
    TopPosts tp
LEFT JOIN 
    UserVotes uv ON tp.PostId = uv.PostId
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
