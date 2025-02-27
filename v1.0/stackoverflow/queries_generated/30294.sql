WITH RecursiveBadgeCount AS (
    SELECT UserId, COUNT(*) AS BadgeCount
    FROM Badges
    GROUP BY UserId
),
UserActivity AS (
    SELECT u.Id AS UserId, 
           u.DisplayName, 
           COALESCE(uc.UpVotes, 0) AS UpVotes, 
           COALESCE(uc.DownVotes, 0) AS DownVotes,
           COALESCE(rb.BadgeCount, 0) AS BadgeCount,
           SUM(p.ViewCount) AS TotalViews,
           SUM(
               CASE 
                   WHEN p.PostTypeId = 1 THEN 1 
                   ELSE 0 
               END
           ) AS QuestionCount,
           SUM(
               CASE 
                   WHEN p.PostTypeId = 2 THEN 1 
                   ELSE 0 
               END
           ) AS AnswerCount
    FROM Users u
    LEFT JOIN (
        SELECT OwnerUserId, 
               SUM(UpVotes) AS UpVotes, 
               SUM(DownVotes) AS DownVotes
        FROM Users
        GROUP BY OwnerUserId
    ) uc ON u.Id = uc.OwnerUserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN RecursiveBadgeCount rb ON u.Id = rb.UserId
    GROUP BY u.Id, u.DisplayName, uc.UpVotes, uc.DownVotes, rb.BadgeCount
),
PostStatistics AS (
    SELECT p.Id AS PostId,
           p.Title,
           p.CreationDate,
           p.Score,
           COALESCE(c.CommentCount, 0) AS CommentCount,
           COALESCE(cl.CloseCount, 0) AS CloseCount,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RowNum
    FROM Posts p
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CommentCount
        FROM Comments
        GROUP BY PostId
    ) c ON p.Id = c.PostId
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS CloseCount
        FROM PostHistory
        WHERE PostHistoryTypeId = 10
        GROUP BY PostId
    ) cl ON p.Id = cl.PostId
)
SELECT ua.DisplayName, 
       ua.UpVotes, 
       ua.DownVotes,
       ua.BadgeCount,
       SUM(ps.ViewCount) AS TotalPostViews,
       COUNT(DISTINCT ps.PostId) AS TotalPosts,
       COUNT(DISTINCT CASE WHEN ps.RowNum = 1 THEN ps.PostId END) AS LatestPosts,
       AVG(ps.Score) AS AvgPostScore,
       SUM(ps.CommentCount) AS TotalComments,
       SUM(ps.CloseCount) AS TotalClosedPosts
FROM UserActivity ua
JOIN PostStatistics ps ON ua.UserId = ps.OwnerUserId
GROUP BY ua.DisplayName, ua.UpVotes, ua.DownVotes, ua.BadgeCount
ORDER BY TotalPosts DESC, TotalPostViews DESC
FETCH NEXT 10 ROWS ONLY;
