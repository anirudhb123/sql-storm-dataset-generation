
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        pt.Name AS PostType,
        u.DisplayName AS Author,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.CreationDate DESC) AS TagRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    WHERE 
        p.CreationDate >= DATE_SUB('2024-10-01', INTERVAL 1 YEAR)
        AND p.Body IS NOT NULL
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.Body,
    rp.CreationDate,
    rp.Score,
    rp.PostType,
    rp.Author,
    rp.CommentCount,
    rp.UpVoteCount,
    GROUP_CONCAT(t.TagName) AS Tags
FROM 
    RankedPosts rp
LEFT JOIN 
    (SELECT 
         p.Id,
         SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '>', -1) AS TagName
     FROM 
         Posts p 
     CROSS JOIN 
         (SELECT a.N + b.N * 10 n FROM 
              (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) a, 
              (SELECT 0 AS N UNION SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9) b) n
     WHERE 
         n.n < 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, '>', '')))
    ) t ON rp.PostId = t.Id
WHERE 
    rp.TagRank < 5  
GROUP BY 
    rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.Score, rp.PostType, rp.Author, rp.CommentCount, rp.UpVoteCount
ORDER BY 
    rp.CreationDate DESC;
