WITH RecursiveUser AS (
    SELECT Id, DisplayName, Reputation, CreationDate, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM Users
), TopUsers AS (
    SELECT Id, DisplayName, Reputation 
    FROM RecursiveUser 
    WHERE UserRank <= 100
), UserPosts AS (
    SELECT u.Id AS UserId, p.Id AS PostId, p.PostTypeId, p.Title, 
           p.CreationDate, p.ViewCount, 
           COUNT(c.Id) AS CommentCount, 
           COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
           COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes
    FROM TopUsers u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY u.Id, p.Id
), PostAnalytics AS (
    SELECT UserId, PostId, COUNT(*) AS EditCount,
           MAX(CreationDate) AS LastEditDate,
           SUM(ViewCount) AS TotalViews,
           SUM(UpVotes - DownVotes) AS Score
    FROM UserPosts
    GROUP BY UserId, PostId
), ClosedPosts AS (
    SELECT ph.PostId, 
           MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
           COUNT(*) FILTER (WHERE ph.PostHistoryTypeId IN (10, 11)) AS HistoryCount
    FROM PostHistory ph
    GROUP BY ph.PostId
)
SELECT u.DisplayName AS User, 
       p.Title AS PostTitle, 
       p.LastEditDate, 
       p.TotalViews, 
       p.Score, 
       c.ClosedDate,
       CASE 
           WHEN c.ClosedDate IS NOT NULL THEN 'Closed'
           ELSE 'Active' 
       END AS PostStatus
FROM PostAnalytics p
LEFT JOIN ClosedPosts c ON p.PostId = c.PostId
JOIN TopUsers u ON p.UserId = u.Id
WHERE p.EditCount > 5
AND (p.TotalViews > 100 OR p.Score > 0)
ORDER BY p.Score DESC, p.TotalViews DESC;
