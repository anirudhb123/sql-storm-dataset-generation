WITH RECURSIVE UserReputation AS (
    SELECT Id, Reputation, 
           CreationDate, 
           DisplayName,
           ARRAY[Reputation] AS ReputationHistory,
           1 AS Level
    FROM Users
    WHERE Reputation > 1000 -- Starting point for users with a decent reputation

    UNION ALL

    SELECT u.Id, 
           u.Reputation, 
           u.CreationDate, 
           u.DisplayName,
           u.ReputationHistory || u.Reputation,
           ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON ur.Level <= 3
    WHERE u.Reputation <= ur.ReputationHistory[1] -- Only consider users with reputation decreasing
)

SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
    COUNT(p.Id) AS TotalPosts,
    MAX(CASE WHEN p.PostTypeId = 1 THEN p.Score ELSE NULL END) AS MaxQuestionScore,
    COUNT(DISTINCT t.Id) AS TotalTags,
    CASE 
        WHEN COUNT(DISTINCT p.Id) > 0 THEN ROUND(AVG(v.VoteAmount), 2)
        ELSE NULL 
    END AS AvgVotes,
    (SELECT COUNT(*) FROM Comments c WHERE c.UserId = u.Id) AS TotalComments
FROM Users u
LEFT JOIN Posts p ON u.Id = p.OwnerUserId
LEFT JOIN PostLinks pl ON p.Id = pl.PostId
LEFT JOIN Tags t ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
LEFT JOIN Votes v ON v.UserId = u.Id AND v.PostId = p.Id AND v.VoteTypeId IN (2, 3) -- Count only Upvotes and Downvotes
GROUP BY u.Id, u.DisplayName
HAVING COUNT(p.Id) > 1 AND COALESCE(SUM(v.BountyAmount), 0) > 0
ORDER BY TotalBounties DESC, UserId ASC
LIMIT 10;

WITH RecentPostVotes AS (
    SELECT p.Id AS PostId,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
           COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
           p.CreationDate
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id
),
MostVotedPosts AS (
    SELECT PostId,
           UpVotes,
           DownVotes,
           ROW_NUMBER() OVER (ORDER BY (UpVotes - DownVotes) DESC, CreationDate ASC) AS PostRank
    FROM RecentPostVotes
)
SELECT 
    p.Title,
    p.Body,
    p.ViewCount,
    m.UpVotes,
    m.DownVotes
FROM Posts p
JOIN MostVotedPosts m ON p.Id = m.PostId
WHERE m.PostRank <= 5
ORDER BY m.UpVotes DESC;
