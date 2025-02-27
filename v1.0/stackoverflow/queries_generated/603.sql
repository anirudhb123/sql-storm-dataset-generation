WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RN,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        p.Id, p.Title, p.Score, p.CreationDate, p.PostTypeId
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.CreationDate,
        rp.CommentCount
    FROM 
        RankedPosts rp
    WHERE 
        rp.RN <= 5
)
SELECT 
    tp.Title,
    COALESCE((SELECT AVG(v.BountyAmount) FROM Votes v WHERE v.PostId = tp.Id AND v.VoteTypeId = 8), 0) AS AvgBounty,
    COUNT(DISTINCT b.Id) AS BadgeCount,
    SUM(CASE WHEN u.Reputation > 1000 THEN 1 ELSE 0 END) AS HighRepUserCount
FROM 
    TopPosts tp
LEFT JOIN 
    Badges b ON b.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id)
LEFT JOIN 
    Users u ON u.Id IN (SELECT OwnerUserId FROM Posts WHERE Id = tp.Id)
GROUP BY 
    tp.Title
HAVING 
    AvgBounty > 0
ORDER BY 
    tp.Score DESC
LIMIT 10;
