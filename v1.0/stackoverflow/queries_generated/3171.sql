WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
PostsWithComments AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate AS PostDate, 
           COUNT(c.Id) AS CommentCount,
           SUM(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END) AS AuthoredComments,
           MAX(c.CreationDate) AS LastCommentDate
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.CreationDate >= '2022-01-01'
    GROUP BY p.Id, p.Title, p.CreationDate
),
TopPosts AS (
    SELECT pwc.PostId, pwc.Title, pwc.PostDate, pwc.CommentCount,
           pr.Id AS OwnerId, pr.DisplayName AS OwnerName,
           u.Reputation AS OwnerReputation
    FROM PostsWithComments pwc
    INNER JOIN Posts pr ON pwc.PostId = pr.Id
    INNER JOIN Users u ON pr.OwnerUserId = u.Id
    WHERE pwc.CommentCount > 5
),
PostLinksCount AS (
    SELECT PostId, COUNT(RelatedPostId) AS LinkCount
    FROM PostLinks
    GROUP BY PostId
)
SELECT tp.PostId, tp.Title, tp.PostDate, tp.CommentCount, 
       tp.OwnerId, tp.OwnerName, tp.OwnerReputation,
       COALESCE(pl.LinkCount, 0) AS LinkCount,
       COALESCE(ur.ReputationRank, 0) AS UserReputationRank
FROM TopPosts tp
LEFT JOIN PostLinksCount pl ON tp.PostId = pl.PostId
LEFT JOIN UserReputation ur ON tp.OwnerId = ur.Id
WHERE tp.OwnerReputation >= (SELECT AVG(Reputation) FROM Users)
  AND tp.CommentCount > (SELECT AVG(CommentCount) FROM PostsWithComments)
ORDER BY tp.CommentCount DESC, tp.OwnerReputation DESC
FETCH FIRST 10 ROWS ONLY;
