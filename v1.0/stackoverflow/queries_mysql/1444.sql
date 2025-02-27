
WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS rn,
        COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
        COALESCE((SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) FROM Votes v WHERE v.PostId = p.Id), 0) AS VoteBalance
    FROM 
        Posts p
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.Score,
    rp.CommentCount,
    rp.VoteBalance,
    CASE 
        WHEN rp.CreationDate < (CAST('2024-10-01 12:34:56' AS DATETIME) - INTERVAL 1 YEAR) THEN 'Old Post' 
        ELSE 'Recent Post' 
    END AS PostAge,
    GROUP_CONCAT(DISTINCT t.TagName) AS TagsList
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    (SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS TagName
     FROM (SELECT @row := @row + 1 AS n FROM 
           (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
            SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
           (SELECT @row := 0) r) numbers 
     WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1) AS t 
WHERE 
    rp.rn <= 5 AND 
    (rp.Score > 0 OR rp.CommentCount > 5)
GROUP BY 
    rp.Id, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.VoteBalance, PostAge
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
LIMIT 50;
