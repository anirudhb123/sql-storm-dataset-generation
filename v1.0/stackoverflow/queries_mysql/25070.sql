
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName ASC) AS Tags,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY COUNT(c.Id) DESC, p.Score DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT TRIM(tag_name) AS tag_name FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag_name
            FROM Posts p CROSS JOIN (SELECT a.N + b.N * 10 + 1 n
            FROM (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
                  SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a,
                 (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION 
                  SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
            WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS subquery) AS tag_name ON TRUE
    LEFT JOIN 
        Tags t ON t.TagName = tag_name
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, u.DisplayName, p.Score
),

TopPosts AS (
    SELECT 
        rp.* 
    FROM 
        RankedPosts rp
    WHERE 
        rp.PostRank <= 5
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.Body,
    tp.CreationDate,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVoteCount,
    tp.DownVoteCount,
    tp.Tags
FROM 
    TopPosts tp
ORDER BY 
    tp.CreationDate DESC;
