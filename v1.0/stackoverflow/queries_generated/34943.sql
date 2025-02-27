WITH RECURSIVE UserConnections AS (
    SELECT u.Id, u.Reputation, u.DisplayName, 1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000 -- Start with users having reputation over 1000
    UNION ALL
    SELECT u.Id, u.Reputation, u.DisplayName, uc.Level + 1
    FROM Users u
    JOIN Votes v ON v.UserId = u.Id
    JOIN UserConnections uc ON uc.Id = v.PostId -- Link to the post voted on
    WHERE uc.Level < 3  -- Limit the depth of the recursion
),
RecentActivity AS (
    SELECT p.OwnerUserId, COUNT(*) AS PostCount, MAX(p.CreationDate) AS LastPostDate
    FROM Posts p
    WHERE p.CreationDate > NOW() - INTERVAL '30 days' -- Consider posts from the last 30 days
    GROUP BY p.OwnerUserId
),
TopUsers AS (
    SELECT u.Id, u.DisplayName, COALESCE(ra.PostCount, 0) AS RecentPostCount
    FROM Users u
    LEFT JOIN RecentActivity ra ON u.Id = ra.OwnerUserId
    WHERE u.Reputation > 5000 -- Filter for high reputation users
)
SELECT 
    uc.DisplayName AS UserName,
    uc.Reputation,
    tu.DisplayName AS TopUser,
    tu.RecentPostCount,
    SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes, -- Count of upvotes
    SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes, -- Count of downvotes
    COUNT(DISTINCT c.Id) AS CommentCount, -- Total comments by the user
    STRING_AGG(DISTINCT p.Title, '; ') AS PostTitles -- Titles of posts related to the user
FROM UserConnections uc
LEFT JOIN Votes v ON v.UserId = uc.Id
LEFT JOIN Comments c ON c.UserId = uc.Id
LEFT JOIN Posts p ON p.OwnerUserId = uc.Id
JOIN TopUsers tu ON uc.Id = tu.Id
WHERE uc.Level > 1
GROUP BY uc.Id, uc.DisplayName, uc.Reputation, tu.DisplayName, tu.RecentPostCount
ORDER BY uc.Reputation DESC, tu.RecentPostCount DESC
LIMIT 10;
