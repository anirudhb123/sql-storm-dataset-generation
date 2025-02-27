
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM 
        Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN (SELECT DISTINCT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '<>', numbers.n), '<>', -1) AS tag
                    FROM (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                          UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                          UNION ALL SELECT 9 UNION ALL SELECT 10) numbers
                    WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '<>', '')) >= numbers.n - 1) AS tag ON TRUE 
        JOIN Tags t ON tag = t.TagName
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR 
        AND p.Score >= 10
    GROUP BY 
        p.Id, pt.Name, p.Title, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    rp.PostRank,
    rp.Tags
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.PostRank, rp.Score DESC;
