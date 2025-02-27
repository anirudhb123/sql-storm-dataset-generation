WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation > 1000 THEN 'High Reputation'
            WHEN Reputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
            ELSE 'Low Reputation'
        END AS ReputationCategory
    FROM Users
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.AcceptedAnswerId,
        COALESCE(a.UserId, -1) AS AcceptedUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        P.VoteCount
    FROM Posts p
    LEFT JOIN Posts a ON p.Id = a.AcceptedAnswerId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate >= '2023-01-01'
    GROUP BY p.Id, p.Title, p.ViewCount, AcceptedUserId
),
PostClosures AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastClosedDate
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY ph.PostId
),
UserPostReputation AS (
    SELECT 
        u.Id AS UserId,
        COUNT(DISTINCT p.Id) AS PostCount,
        AVG(p.Score) AS AverageScore,
        MAX(p.LastActivityDate) AS LastActivePostDate
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id
)
SELECT 
    u.UserId,
    u.Reputation,
    u.ReputationCategory,
    ps.PostId,
    ps.Title,
    ps.ViewCount,
    ps.CommentCount,
    COALESCE(pd.LastClosedDate, 'Never') AS LastClosedDate,
    COALESCE(UPR.PostCount, 0) AS TotalPosts,
    COALESCE(UPR.AverageScore, 0) AS AveragePostScore
FROM UserReputation u
LEFT JOIN PostStatistics ps ON u.UserId = ps.AcceptedUserId
LEFT JOIN PostClosures pd ON ps.PostId = pd.PostId
LEFT JOIN UserPostReputation UPR ON u.UserId = UPR.UserId
WHERE 
    ps.ViewCount > 100 
    AND (ps.CommentCount > 5 OR ps.UpVotes > ps.DownVotes) 
ORDER BY 
    u.Reputation DESC, ps.ViewCount DESC;
