
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COALESCE(c.UserDisplayName, 'Community User') AS OwnerDisplayName,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
)
SELECT TOP 50
    rp.PostId,
    rp.Title,
    rp.OwnerDisplayName,
    rp.CreationDate,
    rp.Score,
    CASE 
        WHEN rp.Score > 10 THEN 'Highly Active'
        WHEN rp.Score BETWEEN 5 AND 10 THEN 'Moderately Active'
        ELSE 'Less Active'
    END AS ActivityLevel,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2) AS UpVoteCount,
    (SELECT COUNT(*) 
     FROM Votes v 
     WHERE v.PostId = rp.PostId AND v.VoteTypeId = 3) AS DownVoteCount
FROM 
    RankedPosts rp
WHERE 
    rp.Rank = 1
ORDER BY 
    rp.Score DESC;
