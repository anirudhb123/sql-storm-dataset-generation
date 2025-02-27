
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostID,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank,
        GROUP_CONCAT(tags.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        (SELECT TRIM(BOTH '\"' FROM tag) AS tag FROM (SELECT DISTINCT TRIM(BOTH '\"' FROM SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1)) AS tag FROM Posts p CROSS JOIN (SELECT @rownum:=@rownum+1 AS n FROM (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n, (SELECT @rownum:=0) r) n WHERE n.n <= 1 + LENGTH(p.Tags) - LENGTH(REPLACE(p.Tags, ',', ''))) AS tag) AS tag ON true
    JOIN 
        Tags tags ON tags.TagName = tag.tag
    WHERE 
        p.PostTypeId = 1 AND 
        p.Score > 0
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.OwnerUserId
),
TopPosts AS (
    SELECT 
        rp.*, 
        RANK() OVER (ORDER BY rp.Score DESC) AS OverallRank
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 3
)
SELECT 
    tp.OwnerDisplayName,
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.CommentCount,
    tp.Tags,
    tp.OverallRank
FROM 
    TopPosts tp
WHERE 
    tp.OverallRank <= 10
ORDER BY 
    tp.OverallRank, tp.Score DESC;
