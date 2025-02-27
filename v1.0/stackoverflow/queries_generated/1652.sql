WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        SUM(p.ViewCount) OVER (PARTITION BY p.OwnerUserId) AS TotalViews,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    r.PostId,
    r.Title,
    r.CreationDate,
    r.Score,
    r.TotalViews,
    r.CommentCount,
    COALESCE(b.Name, 'No Badge') AS BadgeName
FROM 
    Users u
LEFT JOIN 
    RankedPosts r ON u.Id = r.OwnerUserId AND r.rn = 1
LEFT JOIN 
    Badges b ON u.Id = b.UserId AND b.Class = 1
WHERE 
    u.Reputation > 1000
    AND r.Score IS NOT NULL
    AND (EXISTS (
        SELECT 1
        FROM Votes v 
        WHERE v.PostId = r.PostId AND v.VoteTypeId = 2
    ) OR r.CommentCount > 0)
ORDER BY 
    r.Score DESC, r.TotalViews DESC
FETCH FIRST 10 ROWS ONLY;

SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    COALESCE(ph.UserDisplayName, 'Unknown User') AS LastEditor
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.LastEditorUserId = ph.UserId
WHERE 
    p.CreationDate < CURRENT_DATE - INTERVAL '3 months'
    AND (p.Score < 0 OR p.AcceptedAnswerId IS NULL)
    AND NOT EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = p.Id AND v.VoteTypeId IN (2, 3)
    )
ORDER BY 
    p.Score ASC;
