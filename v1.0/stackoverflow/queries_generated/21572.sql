WITH UserScoreCTE AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 
                         WHEN v.VoteTypeId = 3 THEN -1 
                         ELSE 0 END), 0) AS TotalScore,
        COUNT(DISTINCT b.Id) AS TotalBadges,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(AVG(COALESCE(p.Score, 0)), 0) AS AvgPostScore
    FROM Users u
    LEFT JOIN Votes v ON u.Id = v.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
),
PostActivityCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(ph.CreationDate, p.CreationDate) AS LastActivityDate,
        CASE 
            WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 'Answered' 
            WHEN p.PostTypeId = 1 THEN 'Unanswered' 
            ELSE 'Non-Question' 
        END AS PostStatus,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY COALESCE(ph.CreationDate, p.CreationDate) DESC) AS ActivityRank
    FROM Posts p
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
)
SELECT 
    us.UserId,
    us.DisplayName,
    us.TotalScore,
    us.TotalBadges,
    us.TotalPosts,
    us.AvgPostScore,
    pa.PostId,
    pa.Title,
    pa.LastActivityDate,
    pa.PostStatus,
    pa.ActivityRank
FROM UserScoreCTE us
LEFT JOIN PostActivityCTE pa ON us.UserId = pa.PostId
WHERE us.TotalScore > (SELECT AVG(TotalScore) FROM UserScoreCTE) 
OR pa.PostStatus = 'Answered'
ORDER BY us.TotalScore DESC, pa.LastActivityDate DESC
LIMIT 50;

-- Additionally, for bizarre corner case handling
SELECT
    COALESCE(SUM(p.ViewCount) FILTER (WHERE p.ViewCount IS NOT NULL), 0) AS TotalViews,
    COUNT(DISTINCT o.UserId) FILTER (WHERE o.UserId IS NOT NULL) AS UniqueUsersViewed,
    STRING_AGG(DISTINCT CASE WHEN p.Body IS NOT NULL THEN LEFT(p.Body, 100) ELSE 'Body is NULL' END, '; ') AS Snippet
FROM Posts p
LEFT JOIN Comments c ON p.Id = c.PostId
LEFT JOIN Users o ON c.UserId = o.Id
WHERE p.CreationDate >= (
    SELECT MIN(p2.CreationDate) FROM Posts p2 WHERE p2.Score > 0
) AND p.CreationDate < NOW()
GROUP BY p.Id
HAVING TotalViews > 0 AND UniqueUsersViewed >= ALL (
    SELECT COUNT(DISTINCT c2.UserId) 
    FROM Comments c2 GROUP BY c2.PostId
);
This elaborate SQL query structure includes the use of Common Table Expressions (CTEs), aggregations, window functions, and correlated subqueries. It filters for users based on their scores and the status of their posts while incorporating bizarre cases for NULL handling and aggregation of post data.
