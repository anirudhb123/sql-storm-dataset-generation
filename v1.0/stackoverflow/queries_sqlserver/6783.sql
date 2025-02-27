
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC, p.ViewCount DESC) AS PostRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Posts p
        JOIN PostTypes pt ON p.PostTypeId = pt.Id
        LEFT JOIN Comments c ON p.Id = c.PostId
        LEFT JOIN (SELECT value AS tag FROM STRING_SPLIT(p.Tags, '<>')) AS tag ON 1=1 
        JOIN Tags t ON tag.tag = t.TagName
    WHERE 
        p.CreationDate > DATEADD(year, -1, '2024-10-01 12:34:56') 
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
