
WITH PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        GROUP_CONCAT(DISTINCT t.TagName) AS Tags
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        (SELECT DISTINCT t.TagName FROM (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) TagName
        FROM Posts p CROSS JOIN (SELECT a.N + b.N * 10 n FROM 
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) a,
        (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9) b) n
        WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) + 1) AS t) AS t 
    ON TRUE
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName
),
TopPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        (ps.ViewCount + ps.Score + ps.CommentCount + ps.VoteCount) AS EngagementScore
    FROM 
        PostStats ps
    ORDER BY 
        EngagementScore DESC
    LIMIT 10
)
SELECT 
    tp.PostId,
    tp.Title,
    ps.OwnerDisplayName,
    ps.ViewCount,
    ps.Score,
    ps.CommentCount,
    ps.VoteCount,
    ps.Tags 
FROM 
    TopPosts tp
JOIN 
    PostStats ps ON tp.PostId = ps.PostId;
