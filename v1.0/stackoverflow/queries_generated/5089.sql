WITH UserReputation AS (
    SELECT Id, Reputation, Location, UpVotes, DownVotes, Views,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
TopUsers AS (
    SELECT Id, DisplayName, Reputation, Location
    FROM UserReputation
    WHERE ReputationRank <= 100
),
PopularPosts AS (
    SELECT p.Id, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName AS OwnerDisplayName,
           COUNT(c.Id) AS CommentCount
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE p.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY p.Id, u.DisplayName
    HAVING COUNT(c.Id) > 5 -- More than 5 comments
),
PostBadgeSummary AS (
    SELECT p.Id AS PostId, COUNT(b.Id) AS BadgeCount
    FROM Posts p
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    GROUP BY p.Id
),
FinalReport AS (
    SELECT tp.DisplayName, tp.Reputation, tp.Location, pp.Title, pp.Score, pp.ViewCount,
           pp.CommentCount, pbs.BadgeCount
    FROM TopUsers tp
    JOIN PopularPosts pp ON pp.OwnerDisplayName = tp.DisplayName
    JOIN PostBadgeSummary pbs ON pp.Id = pbs.PostId
    ORDER BY tp.Reputation DESC, pp.Score DESC
)
SELECT * FROM FinalReport
WHERE BadgeCount > 0
LIMIT 50;
