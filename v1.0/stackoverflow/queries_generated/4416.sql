WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u
), 
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE -1 END) AS NetScore
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '1 YEAR'
    GROUP BY p.Id, p.OwnerUserId
), 
PostOwners AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        p.PostId,
        pm.CommentCount,
        pm.UpVoteCount,
        pm.DownVoteCount,
        pm.NetScore
    FROM UserReputation ur
    JOIN PostMetrics pm ON ur.UserId = pm.OwnerUserId
    JOIN Posts p ON pm.PostId = p.Id
)
SELECT 
    po.DisplayName,
    SUM(po.CommentCount) AS TotalComments,
    SUM(po.UpVoteCount) AS TotalUpVotes,
    SUM(po.DownVoteCount) AS TotalDownVotes,
    AVG(po.NetScore) AS AverageNetScore,
    COUNT(DISTINCT p.Id) AS TotalPosts
FROM PostOwners po
JOIN Posts p ON po.PostId = p.Id
WHERE po.ReputationRank <= 10
GROUP BY po.DisplayName
ORDER BY TotalUpVotes DESC, TotalComments DESC
LIMIT 5;

-- Fetch users with highest engagement based on comments and upvotes on their posts in the last year.
