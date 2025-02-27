-- Performance Benchmarking Query
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users U ON p.OwnerUserId = U.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
)

SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    Reputation,
    Rank
FROM 
    RankedPosts
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
