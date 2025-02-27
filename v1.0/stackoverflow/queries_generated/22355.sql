WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High-Reputation User'
            WHEN Reputation >= 500  THEN 'Medium-Reputation User'
            ELSE 'Low-Reputation User'
        END AS ReputationCategory
    FROM Users
),
PostMetrics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT ph.Id) FILTER (WHERE ph.PostHistoryTypeId = 10) AS CloseCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9) -- Considering BountyStart and BountyClose votes
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
),
TagPopularity AS (
    SELECT 
        t.TagName,
        COUNT(pt.PostId) AS PostCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM Tags t
    LEFT JOIN Posts pt ON pt.Tags LIKE CONCAT('%<', t.TagName, '>') -- Assuming tags are stored as HTML-like
    LEFT JOIN Users u ON pt.OwnerUserId = u.Id
    GROUP BY t.TagName
),
TopUsers AS (
    SELECT 
        ur.UserId, 
        ur.Reputation,
        RANK() OVER (ORDER BY ur.Reputation DESC) AS UserRank
    FROM UserReputation ur
    WHERE ur.Reputation IS NOT NULL
)

SELECT 
    p.Title,
    p.CreationDate,
    pm.TotalBounties,
    pm.TotalComments,
    pm.CloseCount,
    t.TagName,
    tp.PostCount,
    tp.AvgUserReputation,
    tu.UserId,
    tu.Reputation,
    CASE 
        WHEN pm.TotalComments = 0 THEN 'No Comments'
        ELSE CONCAT(pm.TotalComments, ' Comments')
    END AS CommentsSummary,
    CASE 
        WHEN pm.CloseCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM Posts p
JOIN PostMetrics pm ON p.Id = pm.PostId
CROSS JOIN TagPopularity tp -- To include all tag data for the posts
JOIN TopUsers tu ON pm.TotalBounties > 0 AND tu.UserRank <= 10 -- Focusing on users with high bounties
WHERE 
    (p.CreationDate > NOW() - INTERVAL '1 year') AND 
    (p.ViewCount > 100 OR pm.TotalBounties > 0)
ORDER BY 
    p.ViewCount DESC, 
    pm.CloseCount ASC, 
    tp.PostCount DESC
LIMIT 50;

-- Additional collection of users that have both upvoted and downvoted posts within the last three months
WITH UserVoteBehavior AS (
    SELECT 
        v.UserId,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(*) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT p.Id) FILTER (WHERE p.CreationDate > NOW() - INTERVAL '3 months') AS ActivePostCount
    FROM Votes v
    JOIN Posts p ON v.PostId = p.Id
    GROUP BY v.UserId
)

SELECT 
    u.Id,
    u.DisplayName,
    u.Reputation,
    uv.UpVotes,
    uv.DownVotes,
    uv.ActivePostCount,
    CASE 
        WHEN uv.UpVotes > uv.DownVotes THEN 'Positive Voter'
        WHEN uv.UpVotes < uv.DownVotes THEN 'Negative Voter'
        ELSE 'Neutral Voter'
    END AS VoterType
FROM Users u
JOIN UserVoteBehavior uv ON u.Id = uv.UserId
WHERE uv.ActivePostCount > 0
ORDER BY 
    u.Reputation DESC, 
    uv.UpVotes - uv.DownVotes DESC
LIMIT 20;
