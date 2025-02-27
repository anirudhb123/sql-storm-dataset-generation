WITH RECURSIVE UserReputation AS (
    SELECT u.Id AS UserId, u.Reputation, 1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000
    
    UNION ALL

    SELECT u.Id AS UserId, u.Reputation, ur.Level + 1
    FROM Users u
    JOIN UserReputation ur ON u.Reputation > ur.Reputation
    WHERE ur.Level < 5
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)
    GROUP BY p.Id, p.Title, p.CreationDate, p.OwnerUserId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, u.Reputation,
           ROW_NUMBER() OVER (ORDER BY u.Reputation DESC) AS Rank
    FROM Users u
    WHERE u.Reputation IS NOT NULL
),
ClosedPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.ClosedDate,
           COALESCE(TIMESTAMPDIFF(DAY, p.CreationDate, p.ClosedDate), -1) AS DurationClosed
    FROM Posts p
    WHERE p.ClosedDate IS NOT NULL
),
PostHistorySummary AS (
    SELECT ph.PostId, ph.PostHistoryTypeId, COUNT(ph.Id) AS ChangeCount
    FROM PostHistory ph
    GROUP BY ph.PostId, ph.PostHistoryTypeId
)
SELECT 
    u.DisplayName AS UserName,
    ur.Level AS ReputationLevel,
    ps.Title AS PostTitle,
    ps.CommentCount,
    ps.TotalBounty,
    cp.DurationClosed,
    CASE 
        WHEN cp.DurationClosed IS NOT NULL AND cp.DurationClosed > 0 THEN 'Closed for: ' || phs.ChangeCount || ' modifications'
        ELSE 'Open or not applicable'
    END AS PostStatus
FROM TopUsers u
JOIN UserReputation ur ON u.Id = ur.UserId
JOIN PostStats ps ON u.Id = ps.OwnerUserId
LEFT JOIN ClosedPosts cp ON ps.PostId = cp.Id
LEFT JOIN PostHistorySummary phs ON ps.PostId = phs.PostId
WHERE ur.Level < 5
ORDER BY u.Reputation DESC, ps.CommentCount DESC
FETCH FIRST 100 ROWS ONLY;
