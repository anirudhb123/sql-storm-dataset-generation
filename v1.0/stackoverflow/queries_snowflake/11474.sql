
WITH Benchmark AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        u.DisplayName AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) AS VoteCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, u.DisplayName, p.CreationDate, p.Score, p.ViewCount
)
SELECT 
    *,
    DATEDIFF(SECOND, CreationDate, CURRENT_TIMESTAMP()) AS AgeInSeconds,
    DATEDIFF(SECOND, LastEditDate, CURRENT_TIMESTAMP()) AS TimeSinceLastEditInSeconds
FROM 
    Benchmark
ORDER BY 
    Score DESC, ViewCount DESC;
