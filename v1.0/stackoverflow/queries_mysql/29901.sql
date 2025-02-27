
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) AS VoteCount,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS RowNum
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2  
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id, p.Title, p.Body, p.CreationDate, p.Score, u.DisplayName
), 
FilteredPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.Score,
        rp.OwnerDisplayName,
        rp.CommentCount,
        rp.VoteCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RowNum = 1 
)
SELECT 
    fp.PostId,
    fp.Title,
    fp.Score,
    fp.CommentCount,
    fp.VoteCount,
    CASE 
        WHEN fp.Score > 100 THEN 'High Score'
        WHEN fp.Score BETWEEN 50 AND 100 THEN 'Moderate Score'
        ELSE 'Low Score'
    END AS ScoreCategory,
    GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
FROM 
    FilteredPosts fp 
LEFT JOIN 
    (SELECT 
        SUBSTRING_INDEX(SUBSTRING_INDEX(fp.Body, '><', n.n), '><', -1) AS TagName
    FROM 
        (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) n
    WHERE 
        n.n <= CHAR_LENGTH(fp.Body) - CHAR_LENGTH(REPLACE(fp.Body, '><', '')) + 1) AS t ON TRUE
GROUP BY 
    fp.PostId, fp.Title, fp.Score, fp.CommentCount, fp.VoteCount
ORDER BY 
    fp.Score DESC, fp.CommentCount DESC;
