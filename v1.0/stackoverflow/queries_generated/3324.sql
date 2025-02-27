WITH RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        up.OwnerUserId AS MostActiveUser,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY up.OwnerUserId ORDER BY p.ViewCount DESC) AS PostRank
    FROM 
        Posts p
    LEFT JOIN Users up ON p.OwnerUserId = up.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, up.OwnerUserId, p.Title, p.CreationDate, p.ViewCount
),
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM 
        Users u
)
SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.ViewCount,
    coalesce(CONCAT('User: ', u.DisplayName, ' (Reputation: ', ur.Reputation, ')'), 'Deleted User') AS OwnerInfo,
    rp.CommentCount
FROM 
    RecentPosts rp
LEFT JOIN Users u ON rp.MostActiveUser = u.Id
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
WHERE 
    (rp.CommentCount > 5 OR rp.ViewCount > 100) AND 
    (rp.PostRank = 1 OR ur.ReputationRank <= 10)
ORDER BY 
    rp.ViewCount DESC
LIMIT 50
OFFSET 0;
