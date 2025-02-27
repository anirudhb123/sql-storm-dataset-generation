WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId = 1 AND p.Score > 10
), 
UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        DENSE_RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
)
SELECT 
    rp.Title,
    rp.CreationDate,
    rp.Score,
    ur.Reputation,
    CASE 
        WHEN ur.Reputation >= 1000 THEN 'Highly Reputable'
        WHEN ur.Reputation >= 500 THEN 'Moderately Reputable'
        ELSE 'Less Reputable'
    END AS ReputationCategory,
    COALESCE(pht.Name, 'No History') AS PostHistoryType,
    COUNT(pl.RelatedPostId) AS RelatedPostLinks
FROM RankedPosts rp
LEFT JOIN Users u ON rp.PostId = u.Id
LEFT JOIN UserReputation ur ON ur.UserId = u.Id
LEFT JOIN PostHistory ph ON ph.PostId = rp.PostId
LEFT JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
LEFT JOIN PostLinks pl ON pl.PostId = rp.PostId
WHERE rp.rn = 1
GROUP BY 
    rp.Title, 
    rp.CreationDate, 
    rp.Score, 
    ur.Reputation, 
    pht.Name
HAVING 
    COUNT(pl.RelatedPostId) > 0
ORDER BY 
    rp.Score DESC, 
    ur.ReputationRank ASC
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;
