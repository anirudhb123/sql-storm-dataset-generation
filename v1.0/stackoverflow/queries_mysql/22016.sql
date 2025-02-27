
WITH UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        @rank := @rank + 1 AS ReputationRank
    FROM Users u, (SELECT @rank := 0) r
    ORDER BY u.Reputation DESC
),
ActivePosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        @postRank := IF(@currentUserId = p.OwnerUserId, @postRank + 1, 1) AS PostRank,
        @currentUserId := p.OwnerUserId
    FROM Posts p, (SELECT @postRank := 0, @currentUserId := NULL) r
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE p.CreationDate > NOW() - INTERVAL 30 DAY
    GROUP BY p.Id, p.Title, p.OwnerUserId
),
PostHistoryData AS (
    SELECT 
        ph.PostId,
        ph.PostHistoryTypeId,
        GROUP_CONCAT(ph.Comment SEPARATOR ', ') AS Comments,
        COUNT(*) AS EditCount
    FROM PostHistory ph
    WHERE ph.CreationDate > NOW() - INTERVAL 90 DAY
    GROUP BY ph.PostId, ph.PostHistoryTypeId
),
UserPostSummary AS (
    SELECT 
        ur.UserId,
        ur.DisplayName,
        COUNT(ap.PostId) AS TotalPosts,
        COALESCE(SUM(phd.EditCount), 0) AS TotalEdits,
        SUM(ap.CommentCount) AS TotalComments,
        SUM(ap.UpVotes) AS TotalUpVotes,
        SUM(ap.DownVotes) AS TotalDownVotes
    FROM UserReputation ur
    LEFT JOIN ActivePosts ap ON ur.UserId = ap.OwnerUserId
    LEFT JOIN PostHistoryData phd ON ap.PostId = phd.PostId
    GROUP BY ur.UserId, ur.DisplayName
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalPosts,
    us.TotalEdits,
    us.TotalComments,
    us.TotalUpVotes,
    us.TotalDownVotes,
    CASE 
        WHEN us.TotalUpVotes > us.TotalDownVotes THEN 'Positive Engagement'
        WHEN us.TotalDownVotes > us.TotalUpVotes THEN 'Negative Engagement'
        ELSE 'Neutral Engagement'
    END AS EngagementType,
    ur.ReputationRank
FROM UserPostSummary us
JOIN UserReputation ur ON us.UserId = ur.UserId
WHERE us.TotalPosts > 0
ORDER BY us.TotalPosts DESC, us.TotalComments DESC
LIMIT 5 OFFSET 10;
