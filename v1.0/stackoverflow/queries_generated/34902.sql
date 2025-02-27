WITH RecursiveUserHierarchy AS (
    SELECT Id,
           Reputation,
           CreationDate,
           LastAccessDate,
           DisplayName,
           Location,
           UpVotes,
           DownVotes,
           EmailHash,
           0 AS Level
    FROM Users
    WHERE Reputation > 1000

    UNION ALL

    SELECT u.Id,
           u.Reputation,
           u.CreationDate,
           u.LastAccessDate,
           u.DisplayName,
           u.Location,
           u.UpVotes,
           u.DownVotes,
           u.EmailHash,
           ruh.Level + 1
    FROM Users u
    INNER JOIN RecursiveUserHierarchy ruh ON u.ParentId = ruh.Id
)
, PostActivity AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.ViewCount,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           COALESCE(v.UpVoteCount, 0) AS UpVoteCount,
           COALESCE(v.DownVoteCount, 0) AS DownVoteCount,
           COALESCE(ph.UpdateCount, 0) AS UpdateCount
    FROM Posts p
    LEFT JOIN (
        SELECT PostId,
               COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId,
               SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
               SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount
        FROM Votes
        GROUP BY PostId
    ) v ON p.Id = v.PostId
    LEFT JOIN (
        SELECT PostId,
               COUNT(*) AS UpdateCount
        FROM PostHistory
        WHERE PostHistoryTypeId IN (4, 5, 6) 
        GROUP BY PostId
    ) ph ON p.Id = ph.PostId
)
SELECT u.Id AS UserId,
       u.DisplayName,
       u.Reputation,
       u.Location,
       p.PostId,
       p.Title,
       p.ViewCount,
       p.CommentCount,
       p.UpVoteCount,
       p.DownVoteCount,
       p.UpdateCount,
       ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.ViewCount DESC) AS Ranking
FROM RecursiveUserHierarchy u
JOIN PostActivity p ON p.UserId = u.Id
WHERE u.Reputation BETWEEN 1000 AND 5000
  AND p.ViewCount > 100
  AND (p.CommentCount > 0 OR p.UpVoteCount > 5)
ORDER BY u.Reputation DESC, p.ViewCount DESC;
