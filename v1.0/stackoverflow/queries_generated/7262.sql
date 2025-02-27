WITH UserReputation AS (
    SELECT Id, Reputation, COUNT(DISTINCT p.Id) AS PostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id, u.Reputation
),
MostActiveUsers AS (
    SELECT u.Id, u.DisplayName, ur.PostCount,
           RANK() OVER (ORDER BY ur.PostCount DESC) AS UserRank
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    WHERE ur.PostCount > 10
),
TopPosts AS (
    SELECT p.Id, p.Title, p.Score, p.CreationDate,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM Posts p
    WHERE p.PostTypeId IN (1, 2) -- Questions and Answers
),
PostVotes AS (
    SELECT v.PostId, COUNT(v.Id) AS VoteCount
    FROM Votes v
    GROUP BY v.PostId
)

SELECT
    mau.DisplayName AS UserName,
    mau.PostCount,
    tp.Title AS PostTitle,
    tp.Score AS PostScore,
    COALESCE(pv.VoteCount, 0) AS TotalVotes,
    mau.UserRank
FROM MostActiveUsers mau
JOIN TopPosts tp ON mau.Id = tp.OwnerUserId
LEFT JOIN PostVotes pv ON tp.Id = pv.PostId
WHERE tp.ScoreRank = 1
ORDER BY mau.UserRank, TotalVotes DESC;
