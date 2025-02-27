WITH UserReputation AS (
    SELECT Id, Reputation, CreationDate,
           RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM Users
),
MaxReputation AS (
    SELECT MAX(Reputation) AS MaxRep
    FROM Users
),
PostDetails AS (
    SELECT p.Id AS PostId, p.Title, p.CreationDate, p.Score,
           COALESCE((SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id), 0) AS CommentCount,
           u.DisplayName AS OwnerDisplayName,
           (SELECT SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END)
            FROM Votes v
            WHERE v.PostId = p.Id) AS NetVotes
    FROM Posts p
    LEFT JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.CreationDate >= DATEADD(year, -1, GETDATE())
),
FilteredPosts AS (
    SELECT pd.*, ur.Reputation
    FROM PostDetails pd
    JOIN UserReputation ur ON pd.OwnerDisplayName = ur.Id
    WHERE ur.Reputation > (SELECT MaxRep * 0.1 FROM MaxReputation)
),
RankedPosts AS (
    SELECT *,
           DENSE_RANK() OVER (PARTITION BY Reputation ORDER BY Score DESC) AS ScoreRank
    FROM FilteredPosts
),
FinalOutput AS (
    SELECT *,
           CASE 
               WHEN CommentCount > 10 THEN 'High Engagement'
               ELSE 'Low Engagement'
           END AS EngagementLevel
    FROM RankedPosts
)
SELECT PostId, Title, CreationDate, Score, CommentCount, OwnerDisplayName, Reputation, ScoreRank, EngagementLevel
FROM FinalOutput
WHERE ScoreRank = 1
ORDER BY Reputation DESC, Score DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;

-- Additional complexity with JSON handling for comments
SELECT p.PostId, 
       STRING_AGG(c.Text, ' | ') AS Comments
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
WHERE p.Id IN (SELECT PostId FROM FinalOutput)
GROUP BY p.PostId;
