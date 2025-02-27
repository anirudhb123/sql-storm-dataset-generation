
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON c.PostId = p.Id
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    WHERE 
        p.PostTypeId = 1 AND 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount, p.Tags
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Score,
        ViewCount,
        Tags,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        rn = 1 
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.CommentCount,
    tp.VoteCount,
    (SELECT GROUP_CONCAT(DISTINCT Tag) 
     FROM (
         SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, '><', n.n), '><', -1)) AS Tag
         FROM (SELECT a.N + b.N * 10 + 1 n
               FROM 
                  (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                   UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
                  (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                   UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b
                  ORDER BY n) n
         WHERE n.n <= LENGTH(tp.Tags) - LENGTH(REPLACE(tp.Tags, '><', '')) + 1
     ) AS tag_list) AS ParsedTags,
    (SELECT GROUP_CONCAT(DISTINCT CONCAT(u.DisplayName, ' (Reputation: ', u.Reputation, ')') SEPARATOR ', ')
     FROM Users u
     WHERE u.Id IN (SELECT DISTINCT c.UserId FROM Comments c WHERE c.PostId = tp.PostId)) AS Commenters
FROM 
    TopPosts tp
ORDER BY 
    tp.Score DESC;
