WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation >= 1000 THEN 'High'
            WHEN Reputation >= 500 THEN 'Medium'
            ELSE 'Low'
        END AS ReputationLevel
    FROM Users
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 2) AS UpvoteCount,
        COUNT(DISTINCT v.UserId) FILTER (WHERE v.VoteTypeId = 3) AS DownvoteCount,
        AVG(r.Reputation) AS AvgReputation
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN UserReputation r ON p.OwnerUserId = r.UserId
    WHERE p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY p.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        MAX(ph.CreationDate) OVER (PARTITION BY ph.PostId) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10
),
PostDetails AS (
    SELECT 
        ps.PostId,
        ps.CommentCount,
        ps.UpvoteCount,
        ps.DownvoteCount,
        cp.LastClosedDate,
        COALESCE(cp.LastClosedDate, ps.CreationDate) AS EffectiveClosureDate
    FROM PostStats ps
    LEFT JOIN ClosedPosts cp ON ps.PostId = cp.PostId
),
TopUsers AS (
    SELECT 
        ur.UserId,
        SUM(ps.UpvoteCount) - SUM(ps.DownvoteCount) AS NetVotes,
        ROW_NUMBER() OVER (ORDER BY SUM(ps.UpvoteCount) - SUM(ps.DownvoteCount) DESC) AS Rank
    FROM PostDetails pd
    JOIN Users ur ON pd.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = ur.Id)
    JOIN PostStats ps ON pd.PostId = ps.PostId
    GROUP BY ur.UserId
    HAVING SUM(ps.CommentCount) > 0
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ud.ReputationLevel,
    pd.CommentCount,
    pd.UpvoteCount,
    pd.DownvoteCount,
    ROUND(100.0 * pd.UpvoteCount / NULLIF(pd.UpvoteCount + pd.DownvoteCount, 0), 2) AS UpvotePercentage,
    tu.NetVotes,
    tu.Rank
FROM Users u
JOIN UserReputation ud ON u.Id = ud.UserId
JOIN PostDetails pd ON u.Id = pd.OwnerUserId
JOIN TopUsers tu ON u.Id = tu.UserId
WHERE 
    u.CreationDate < pd.EffectiveClosureDate 
    AND pd.EffectiveClosureDate IS NOT NULL
ORDER BY tu.NetVotes DESC, u.Reputation DESC;

