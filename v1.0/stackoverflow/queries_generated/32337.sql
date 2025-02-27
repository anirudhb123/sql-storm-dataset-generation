WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, 
           CAST(DisplayName AS VARCHAR(100)) AS Path,
           1 AS Level
    FROM Users
    WHERE Reputation > 1000  -- Starting with users who have a reputation above 1000

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation,
           CONCAT(uh.Path, ' -> ', u.DisplayName) AS Path,
           uh.Level + 1
    FROM Users u
    JOIN UserHierarchy uh ON u.Id IN (
        SELECT CreatedByUserId  -- Assuming there's a connection we can use
        FROM Posts
        WHERE OwnerUserId = uh.Id
    )
    WHERE uh.Level < 5  -- Limit hierarchy depth to 5 levels
),
PostStatistics AS (
    SELECT p.Id AS PostId,
           p.Title,
           COUNT(c.Id) AS CommentCount,
           SUM(v.VoteTypeId = 2) AS Upvotes,
           SUM(v.VoteTypeId = 3) AS Downvotes,
           (SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3)) AS NetVotes,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS Rank
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL '30 days'  -- Posts created in the last 30 days
    GROUP BY p.Id, p.Title
),
TopPosts AS (
    SELECT PostId, Title, CommentCount, NetVotes,
           RANK() OVER (ORDER BY NetVotes DESC) AS PostRank
    FROM PostStatistics
)
SELECT uh.Path, tp.Title, tp.CommentCount, tp.NetVotes, 
       COALESCE(SUM(b.Class), 0) AS TotalBadges
FROM UserHierarchy uh
LEFT JOIN Posts p ON uh.Id = p.OwnerUserId
LEFT JOIN TopPosts tp ON p.Id = tp.PostId
LEFT JOIN Badges b ON uh.Id = b.UserId 
WHERE tp.PostRank <= 10  -- Get top 10 posts for users
AND uh.Level < 5  -- Limiting to user hierarchy levels
GROUP BY uh.Path, tp.Title, tp.CommentCount, tp.NetVotes
ORDER BY TotalBadges DESC, NetVotes DESC;
