WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    rp.CommentCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    RankedPosts rp
JOIN 
    Users u ON rp.PostId = u.Id
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    rp.PostRank = 1
    AND EXISTS (
        SELECT 1
        FROM Votes v
        WHERE v.PostId = rp.PostId AND v.VoteTypeId = 2
    )
ORDER BY 
    rp.ViewCount DESC
LIMIT 10;

UNION ALL

SELECT 
    u.DisplayName,
    p.Id AS PostId,
    p.Title,
    p.CreationDate,
    p.ViewCount,
    COALESCE(cp.CommentCount, 0) AS CommentCount,
    'No Badge' AS BadgeName
FROM 
    Posts p
LEFT JOIN 
    (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) cp ON p.Id = cp.PostId
JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    p.CreationDate < NOW() - INTERVAL '1 year' 
    AND p.AcceptedAnswerId IS NULL
ORDER BY 
    p.ViewCount DESC
LIMIT 5;
