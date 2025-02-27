
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerName,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName, p.PostTypeId
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerName,
    rp.Score,
    rp.ViewCount,
    rp.CommentCount,
    CASE 
        WHEN rp.PostRank = 1 THEN 'Most Recent'
        ELSE CONCAT('Rank ', rp.PostRank)
    END AS PostRankDescription
FROM 
    RankedPosts rp
WHERE 
    rp.PostRank <= 5
ORDER BY 
    rp.CreationDate DESC;
