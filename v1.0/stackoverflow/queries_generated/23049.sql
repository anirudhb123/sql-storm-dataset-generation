WITH UserReputation AS (
    SELECT Id, Reputation,
           CASE 
               WHEN Reputation IS NULL THEN 'No Reputation'
               WHEN Reputation < 50 THEN 'Low Reputation'
               WHEN Reputation BETWEEN 50 AND 200 THEN 'Medium Reputation'
               ELSE 'High Reputation'
           END AS ReputationCategory
    FROM Users
),
PostAnalytics AS (
    SELECT p.Id AS PostId, 
           p.OwnerUserId,
           p.PostTypeId,
           p.CreationDate,
           p.Score,
           p.ViewCount,
           U.Reputation AS OwnerReputation,
           COUNT(DISTINCT c.Id) AS CommentCount,
           COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVoteCount,
           COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVoteCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN UserReputation U ON U.Id = p.OwnerUserId
    WHERE p.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id, p.OwnerUserId, p.PostTypeId, p.CreationDate, p.Score, p.ViewCount, U.Reputation
),
TopPosts AS (
    SELECT *,
           CASE
               WHEN Score > 100 THEN 'Popular'
               WHEN Score BETWEEN 50 AND 100 THEN 'Moderate'
               ELSE 'Less Popular'
           END AS Popularity
    FROM PostAnalytics
    WHERE OwnerReputation > 50
),
ClosedPosts AS (
    SELECT p.Id AS ClosedPostId, PC.PostId, p.OwnerUserId, p.ClosedDate, p.Title
    FROM PostHistory ph
    JOIN Posts p ON p.Id = ph.PostId
    JOIN PostHistoryTypes pht ON pht.Id = ph.PostHistoryTypeId
    JOIN Posts PC ON PC.Id = ph.PostId
    WHERE pht.Name = 'Post Closed'
      AND p.ClosedDate IS NOT NULL
),
PostSummary AS (
    SELECT tp.PostId, 
           tp.Title, 
           tp.OwnerUserId, 
           tp.Popularity,
           COALESCE(cp.ClosedPostId, 0) AS IsClosed,
           CASE 
               WHEN cp.ClosedPostId IS NOT NULL THEN 'Closed'
               ELSE 'Open'
           END AS Status
    FROM TopPosts tp
    LEFT JOIN ClosedPosts cp ON tp.PostId = cp.PostId
)
SELECT ps.PostId, 
       ps.Title,
       u.DisplayName AS OwnerName,
       ps.Popularity,
       ps.Status,
       ps.IsClosed,
       COUNT(c.Id) AS TotalComments,
       SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
       SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
       DENSE_RANK() OVER (ORDER BY ps.Popularity DESC) AS PopularityRank
FROM PostSummary ps
JOIN Users u ON ps.OwnerUserId = u.Id
LEFT JOIN Comments c ON ps.PostId = c.PostId
LEFT JOIN Votes v ON ps.PostId = v.PostId
GROUP BY ps.PostId, ps.Title, u.DisplayName, ps.Popularity, ps.Status, ps.IsClosed
ORDER BY ps.PopularityRank, ps.Title;
