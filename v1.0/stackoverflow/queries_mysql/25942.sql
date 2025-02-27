
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, p.Tags
),
TopPosts AS (
    SELECT 
        PostId, 
        Title, 
        ViewCount, 
        Score, 
        Tags,
        CommentCount, 
        UpVotes, 
        DownVotes
    FROM 
        RankedPosts 
    WHERE 
        rn = 1 
    ORDER BY 
        Score DESC, ViewCount DESC
    LIMIT 10
),
PostTags AS (
    SELECT 
        p.Id AS PostId,
        GROUP_CONCAT(t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', n.n), '<>', -1) AS TagName
         FROM Posts p CROSS JOIN 
         (SELECT a.N + b.N * 10 + 1 n FROM 
         (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
          SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
          SELECT 8 UNION ALL SELECT 9) a, 
         (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
          SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
          SELECT 8 UNION ALL SELECT 9) b
         ) n
         WHERE n.n <= 1 + (LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '<>', ''))) ) AS tag ON TRUE
    JOIN 
        Tags t ON t.TagName = tag.TagName
    GROUP BY 
        p.Id
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    pt.Tags AS ProcessedTags
FROM 
    TopPosts tp
JOIN 
    PostTags pt ON tp.PostId = pt.PostId
ORDER BY 
    tp.Score DESC;
