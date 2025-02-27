
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
        WHEN rp.CreationDate < DATEADD(YEAR, -1, '2024-10-01 12:34:56') THEN 'Old Post' 
        ELSE 'Recent Post' 
    END AS PostAge,
    STRING_AGG(DISTINCT t.TagName, ',') AS TagsList
FROM 
    RankedPosts rp
LEFT JOIN 
    Posts p ON rp.Id = p.Id
LEFT JOIN 
    (SELECT 
        Id, 
        value AS TagName 
     FROM 
        Posts CROSS APPLY STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '><')) AS t) 
    ON rp.Id = p.Id
WHERE 
    rp.rn <= 5 AND 
    (rp.Score > 0 OR rp.CommentCount > 5)
GROUP BY 
    rp.Id, rp.Title, rp.CreationDate, rp.ViewCount, rp.Score, rp.CommentCount, rp.VoteBalance, PostAge
ORDER BY 
    rp.Score DESC, rp.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY;
