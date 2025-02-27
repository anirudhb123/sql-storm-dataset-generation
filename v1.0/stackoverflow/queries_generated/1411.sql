WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), 
TopPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank,
        COUNT(c.Id) OVER (PARTITION BY p.Id) AS CommentCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    AND p.Score > 0
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.Comment
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE pht.Name = 'Post Closed'
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.Location,
    tp.PostId,
    tp.Title,
    tp.Score,
    tp.CreationDate AS PostCreationDate,
    tp.CommentCount,
    (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS Upvotes,
    COALESCE(cp.CreationDate, 'Never Closed') AS LastClosedDate,
    COALESCE(cp.Comment, 'No Comments') AS CloseReason
FROM UserReputation u
JOIN TopPosts tp ON u.UserId = tp.OwnerUserId
LEFT JOIN ClosedPosts cp ON tp.PostId = cp.PostId
WHERE u.Reputation > 100
AND tp.RecentPostRank = 1
ORDER BY u.Reputation DESC, tp.Score DESC
LIMIT 100;
