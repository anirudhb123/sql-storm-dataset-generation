WITH RECURSIVE UserReputation AS (
    SELECT 
        Id,
        Reputation,
        DisplayName,
        CreationDate,
        1 AS Level
    FROM Users
    WHERE Reputation > 1000
    
    UNION ALL
    
    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Id = ur.Id
    WHERE u.Reputation >= ur.Reputation * 0.9
),

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(comment.Id) AS TotalComments,
        SUM(v.VoteTypeId = 2) AS Upvotes,
        SUM(v.VoteTypeId = 3) AS Downvotes,
        SUM(v.VoteTypeId IN (2, 3)) AS TotalVotes,
        AVG(p.Score) OVER (PARTITION BY p.OwnerUserId) AS AvgUserScore
    FROM Posts p
    LEFT JOIN Comments comment ON p.Id = comment.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY p.Id, p.OwnerUserId
),

UserPostStats AS (
    SELECT 
        u.DisplayName,
        COUNT(ps.PostId) AS PostCount,
        SUM(ps.TotalComments) AS TotalComments,
        SUM(ps.Upvotes) AS TotalUpvotes,
        SUM(ps.Downvotes) AS TotalDownvotes,
        MAX(ps.AvgUserScore) AS MaxAvgUserScore
    FROM Users u
    LEFT JOIN PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY u.DisplayName
)

SELECT 
    up.DisplayName,
    up.PostCount,
    up.TotalComments,
    up.TotalUpvotes,
    up.TotalDownvotes,
    CASE 
        WHEN up.MaxAvgUserScore IS NULL THEN 'No Score'
        WHEN up.MaxAvgUserScore > 50 THEN 'Expert'
        ELSE 'Novice'
    END AS UserCategory
FROM UserPostStats up
WHERE up.TotalUpvotes > 10
ORDER BY up.TotalUpvotes DESC;

-- Additional analysis of post history (to find edits and closures)
SELECT 
    ph.UserDisplayName,
    p.Title,
    ph.CreationDate AS EditDate,
    ph.Comment,
    ph.PostHistoryTypeId,
    CASE 
        WHEN ph.PostHistoryTypeId = 10 THEN 'Closed'
        WHEN ph.PostHistoryTypeId = 11 THEN 'Reopened'
        ELSE 'Edited'
    END AS ChangeType
FROM PostHistory ph
JOIN Posts p ON ph.PostId = p.Id
WHERE ph.CreationDate >= NOW() - INTERVAL '1 year'
ORDER BY ph.CreationDate DESC;
