WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        u.LastAccessDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id
), 

PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(CAST(ROUND(AVG(v.voteTypeId = 2)::decimal / NULLIF(COUNT(v.Id), 0) * 100, 2) AS numeric), 0.0) AS UpvotePercentage,
        COALESCE(CAST(ROUND(AVG(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END)::decimal / NULLIF(COUNT(ph.Id), 0) * 100, 2) AS numeric), 0.0) AS ClosePercentage
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
),

UserPostMax AS (
    SELECT 
        ua.UserId,
        ua.DisplayName,
        MAX(ps.ViewCount) AS MaxPostViews
    FROM UserActivity ua
    JOIN PostStats ps ON ps.PostId IN (
        SELECT p.Id
        FROM Posts p
        WHERE p.OwnerUserId = ua.UserId
    )
    GROUP BY ua.UserId, ua.DisplayName
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.Reputation,
    ua.PostCount,
    ua.TotalViews,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    up.MaxPostViews,
    CASE 
        WHEN ua.Reputation > 1000 THEN 'High Reputation'
        WHEN ua.Reputation BETWEEN 100 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    (SELECT STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN STRING_TO_ARRAY(p.Tags, '>') AS tag ON tag IS NOT NULL
     JOIN Tags t ON t.TagName = tag 
     WHERE p.OwnerUserId = ua.UserId) AS Tags
FROM UserActivity ua
LEFT JOIN UserPostMax up ON ua.UserId = up.UserId
ORDER BY ua.TotalViews DESC, ua.Reputation DESC
LIMIT 20;
