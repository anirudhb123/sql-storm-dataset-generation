WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id
), UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COALESCE(b.Class, 0) AS BadgeClass
    FROM 
        Users u
    LEFT JOIN 
        (SELECT UserId, MAX(Class) AS Class
         FROM Badges 
         GROUP BY UserId) b ON u.Id = b.UserId
)
SELECT 
    up.RecentPostRank,
    up.Title,
    up.CommentCount,
    ur.DisplayName,
    ur.Reputation,
    ur.BadgeClass
FROM 
    RecentPosts up
JOIN 
    UserReputation ur ON up.OwnerUserId = ur.UserId
WHERE 
    ur.Reputation > 1000
    AND (ur.CreationDate < NOW() - INTERVAL '2 years' OR ur.BadgeClass = 1)
    AND EXISTS (
        SELECT 1 
        FROM Votes v 
        WHERE v.PostId = up.PostId 
        AND v.VoteTypeId IN (2, 3) 
        HAVING COUNT(v.VoteTypeId) > 5
    )
ORDER BY 
    up.CommentCount DESC, 
    ur.Reputation ASC
LIMIT 10;

-- Optional: Check for posts that have been closed or deleted
UNION ALL

SELECT 
    'closed_or_deleted' AS PostType,
    p.Title AS PostTitle,
    p.CreationDate AS CommentDate,
    u.DisplayName AS CommentUser,
    NULL AS Reputation,
    NULL AS BadgeClass
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    Users u ON p.OwnerUserId = u.Id
WHERE 
    ph.PostHistoryTypeId IN (10, 12)  -- 10 = Post Closed, 12 = Post Deleted
ORDER BY 
    p.CreationDate DESC
LIMIT 5;
