WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS OwnerRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 AND p.Score IS NOT NULL
    GROUP BY p.Id, p.Title, p.Score, p.CreationDate, p.OwnerUserId
),

UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        CASE
            WHEN u.Reputation IS NULL THEN 'No Reputation'
            WHEN u.Reputation < 100 THEN 'Low Reputation'
            WHEN u.Reputation BETWEEN 100 AND 1000 THEN 'Moderate Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM Users u
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.Score,
    rp.CreationDate,
    u.DisplayName,
    u.Reputation,
    ur.ReputationCategory,
    rp.CommentCount,
    COALESCE((
        SELECT STRING_AGG(c.Text, ', ')
        FROM Comments c 
        WHERE c.PostId = rp.PostId
    ), 'No comments') AS Comments,
    ROW_NUMBER() OVER (PARTITION BY rp.OwnerUserId ORDER BY rp.Score DESC) AS PostRank,
    COUNT(DISTINCT CASE WHEN bh.Id IS NOT NULL THEN 1 END) AS TotalBadges
FROM RankedPosts rp
JOIN Users u ON u.Id = rp.OwnerUserId
LEFT JOIN Badges bh ON bh.UserId = u.Id
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
WHERE rp.OwnerRank = 1 AND ur.Reputation > 50
GROUP BY rp.PostId, rp.Title, rp.Score, rp.CreationDate, 
         u.DisplayName, u.Reputation, ur.ReputationCategory, rp.CommentCount
HAVING COUNT(DISTINCT bh.Id) > 2 OR EXISTS (
    SELECT 1 
    FROM Votes v 
    WHERE v.PostId = rp.PostId AND v.VoteTypeId IN (2, 3)
)
ORDER BY rp.CreationDate DESC, rp.Score DESC;
