WITH RECURSIVE UserReputationCTE AS (
    SELECT Id, Reputation, CreationDate,
           ROW_NUMBER() OVER (PARTITION BY Reputation ORDER BY CreationDate) AS Rank
    FROM Users
    WHERE Reputation > 0
), PopularPosts AS (
    SELECT p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, 
           COALESCE(a.Body, 'No accepted answer') AS AcceptedAnswer,
           COALESCE(c.SumComments, 0) AS TotalComments
    FROM Posts p
    LEFT JOIN (
        SELECT ParentId, COUNT(*) AS SumComments
        FROM Comments
        GROUP BY ParentId
    ) AS c ON p.Id = c.ParentId
    LEFT JOIN Posts a ON p.AcceptedAnswerId = a.Id
    WHERE p.PostTypeId = 1 AND p.ClosedDate IS NULL
    ORDER BY p.Score DESC
    LIMIT 10
), UserBadges AS (
    SELECT u.Id AS UserId, b.Name AS BadgeName, b.Class,
           ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY b.Date DESC) AS BadgeRank
    FROM Users u
    JOIN Badges b ON u.Id = b.UserId
    WHERE b.Class = 1 OR b.Class = 2 -- Gold or Silver badges
), UserActivity AS (
    SELECT u.Id AS UserId, SUM(COALESCE(p.ViewCount, 0)) AS TotalViews, 
           AVG(COALESCE(c.Score, 0)) AS AvgCommentScore
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    WHERE u.Reputation > 100
    GROUP BY u.Id
)
SELECT u.Id AS UserId, u.DisplayName, 
       COALESCE(rb.Badges, 'No badges') AS BadgesEarned,
       ua.TotalViews, ua.AvgCommentScore,
       p.Id AS PopularPostId, p.Title AS PopularPostTitle,
       p.Score AS PopularPostScore, p.AcceptedAnswer,
       CONCAT('Activity recorded on: ', TO_CHAR(NOW(), 'YYYY-MM-DD HH24:MI:SS')) AS ActivityTimestamp
FROM Users u
LEFT JOIN (
    SELECT UserId, STRING_AGG(BadgeName, ', ') AS Badges
    FROM UserBadges
    WHERE BadgeRank = 1
    GROUP BY UserId
) rb ON u.Id = rb.UserId
LEFT JOIN UserActivity ua ON u.Id = ua.UserId
LEFT JOIN PopularPosts p ON ua.TotalViews > 250 
WHERE u.Reputation > 500
ORDER BY u.Reputation DESC, ua.TotalViews DESC, p.Score DESC;

