WITH RECURSIVE TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation, 
           ROW_NUMBER() OVER(ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
),
RecentPostHistory AS (
    SELECT ph.UserId, ph.PostId, ph.PostHistoryTypeId, ph.CreationDate,
           ROW_NUMBER() OVER(PARTITION BY ph.UserId ORDER BY ph.CreationDate DESC) AS HistoryRank
    FROM PostHistory ph
    WHERE ph.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
),
TopPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, 
           COUNT(DISTINCT c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3) AS NetVotes
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '90 days'
    GROUP BY p.Id
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation AS UserReputation,
    COUNT(DISTINCT p.Id) AS TotalPosts,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalCloseVotes,
    STRING_AGG(DISTINCT t.TagName, ', ') AS Tags,
    p.Title AS PostTitle,
    p.CreationDate AS PostDate,
    p.Score AS PostScore,
    COALESCE(r.PostId, 0) AS RecentPostId,
    COALESCE(r.HistoryRank, 0) AS RecentHistoryRank
FROM Users u
INNER JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN RecentPostHistory r ON u.Id = r.UserId AND r.HistoryRank = 1
LEFT JOIN Tags t ON p.Tags LIKE '%' || t.TagName || '%'
WHERE u.Reputation > 100 AND 
      EXISTS (SELECT 1 FROM Votes v WHERE v.PostId = p.Id AND v.UserId = u.Id)
GROUP BY u.Id, p.Title, p.CreationDate, p.Score, r.PostId, r.HistoryRank
HAVING COUNT(DISTINCT p.Id) > 5
ORDER BY TotalPosts DESC, UserReputation DESC
LIMIT 10;
