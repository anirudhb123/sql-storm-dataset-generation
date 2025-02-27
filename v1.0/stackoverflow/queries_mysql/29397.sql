
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS Author,
        p.Score,
        p.ViewCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
        LEFT JOIN Users u ON p.OwnerUserId = u.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN Votes v ON p.Id = v.PostId
        LEFT JOIN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS tag
                   FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                         UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                         UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                   WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS tag ON TRUE
        JOIN Tags t ON tag.tag = t.TagName
    WHERE 
        p.CreationDate >= '2024-09-30 12:34:56'
    GROUP BY 
        p.Id, u.DisplayName, p.Title, p.Body, p.CreationDate, p.Score, p.ViewCount
),
TopPosts AS (
    SELECT 
        PostId,
        Title,
        Body,
        CreationDate,
        Author,
        Score,
        ViewCount,
        Tags,
        CommentCount,
        VoteCount
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)
SELECT 
    tp.Title,
    tp.Author,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.VoteCount,
    TRIM(TRAILING ',' FROM GROUP_CONCAT(tag_name)) AS TagList
FROM 
    TopPosts tp
    LEFT JOIN (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(tp.Tags, ',', numbers.n), ',', -1) AS tag_name
                FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
                      UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8
                      UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                WHERE CHAR_LENGTH(tp.Tags) - CHAR_LENGTH(REPLACE(tp.Tags, ',', '')) >= numbers.n - 1) AS tag_name ON TRUE
GROUP BY 
    tp.PostId, tp.Title, tp.Author, tp.CreationDate, tp.ViewCount, tp.Score, tp.CommentCount, tp.VoteCount
ORDER BY 
    tp.Score DESC, tp.ViewCount DESC;
