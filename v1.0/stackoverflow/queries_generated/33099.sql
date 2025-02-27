WITH RecursivePostCTE AS (
    -- Recursive Common Table Expression to get the hierarchy of answers
    SELECT Id, Title, Body, OwnerUserId, ParentId, CreationDate, LastActivityDate,
           CAST(Title AS VARCHAR(300)) AS FullTitle, 1 AS Level
    FROM Posts
    WHERE PostTypeId = 1 -- Questions

    UNION ALL

    SELECT a.Id, a.Title, a.Body, a.OwnerUserId, a.ParentId, a.CreationDate, a.LastActivityDate,
           CAST(CONCAT_WS(' -> ', r.FullTitle, a.Title) AS VARCHAR(300)) AS FullTitle, 
           r.Level + 1
    FROM Posts a
    INNER JOIN RecursivePostCTE r ON a.ParentId = r.Id
    WHERE a.PostTypeId = 2 -- Answers
), 
UserActivity AS (
    -- CTE to aggregate user activities and total votes
    SELECT u.Id AS UserId, 
           u.DisplayName,
           SUM(COALESCE(v.vote_count, 0)) AS TotalVotes,
           COUNT(DISTINCT p.Id) AS PostCount,
           COUNT(DISTINCT b.Id) AS BadgeCount,
           AVG(u.Reputation) AS AvgReputation
    FROM Users u
    LEFT JOIN (
        SELECT PostId, COUNT(*) AS vote_count
        FROM Votes
        GROUP BY PostId
    ) v ON v.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Badges b ON b.UserId = u.Id
    GROUP BY u.Id
),
TopUsers AS (
    -- Select to find the top users based on total votes
    SELECT UserId, DisplayName, TotalVotes, PostCount, BadgeCount, AvgReputation,
           RANK() OVER (ORDER BY TotalVotes DESC) AS Rank
    FROM UserActivity
),
ClosedPosts AS (
    -- Select to fetch posts that have been closed
    SELECT p.Id, p.Title, ph.CreationDate, ph.Comment, ph.UserDisplayName
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId 
    WHERE ph.PostHistoryTypeId = 10 -- Closed posts
)
SELECT 
    r.Id AS PostId,
    r.FullTitle AS PostFullTitle,
    r.CreationDate AS PostCreationDate,
    r.LastActivityDate AS PostLastActivityDate,
    u.DisplayName AS OwnerName,
    u.Reputation AS OwnerReputation,
    t.UserId AS TopUserId,
    t.DisplayName AS TopUserName,
    t.TotalVotes AS TopUserVotes,
    CASE 
        WHEN cp.Id IS NOT NULL THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM RecursivePostCTE r
JOIN Users u ON r.OwnerUserId = u.Id
LEFT JOIN TopUsers t ON u.Id = t.UserId AND t.Rank <= 10 -- Top 10 users
LEFT JOIN ClosedPosts cp ON r.Id = cp.Id
WHERE r.Level <= 3 -- Include questions and their direct answers only
ORDER BY r.LastActivityDate DESC, t.TotalVotes DESC;
