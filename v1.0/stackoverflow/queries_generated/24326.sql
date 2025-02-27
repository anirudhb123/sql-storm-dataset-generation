WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           DENSE_RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
), RecentPosts AS (
    SELECT p.OwnerUserId, p.Id AS PostId, p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '1 year'
), AcceptedAnswers AS (
    SELECT a.OwnerUserId, a.Id AS AcceptedAnswerId,
           COALESCE(v.VoteCount, 0) AS Upvotes, v.VoteTypeId
    FROM Posts a
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS VoteCount, VoteTypeId
        FROM Votes
        WHERE VoteTypeId = 2
        GROUP BY PostId, VoteTypeId
    ) v ON a.AcceptedAnswerId = v.PostId
    WHERE a.PostTypeId = 1
), PostComments AS (
    SELECT PostId, COUNT(*) AS CommentCount
    FROM Comments
    GROUP BY PostId
), UniqueTags AS (
    SELECT p.Id AS PostId, 
           ARRAY_AGG(DISTINCT TRIM(BOTH '<>' FROM UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>'))) ) ) AS TagArray
    FROM Posts p
    WHERE p.Tags IS NOT NULL AND p.Tags <> ''
    GROUP BY p.Id
), PostHistoryAnalysis AS (
    SELECT ph.PostId, COUNT(*) AS HistoryChangeCount,
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedCount,
           MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenedCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT u.DisplayName, u.Reputation, u.CreationDate,
       rp.RecentPostRank, aa.Upvotes, pc.CommentCount, 
       p.TagArray, pha.HistoryChangeCount, pha.ClosedCount, pha.ReopenedCount
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.Id
LEFT JOIN RecentPosts rp ON u.Id = rp.OwnerUserId AND rp.RecentPostRank = 1
LEFT JOIN AcceptedAnswers aa ON u.Id = aa.OwnerUserId
LEFT JOIN PostComments pc ON pc.PostId = rp.PostId
LEFT JOIN UniqueTags p ON p.PostId = rp.PostId
LEFT JOIN PostHistoryAnalysis pha ON pha.PostId = rp.PostId
WHERE u.Reputation > 1000 
  AND (rp.RecentPostRank IS NOT NULL OR aa.Upvotes > 0)
ORDER BY u.Reputation DESC, rp.RecentPostRank ASC
LIMIT 50;
