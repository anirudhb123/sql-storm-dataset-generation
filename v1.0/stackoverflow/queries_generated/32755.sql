WITH RECURSIVE UserPostCount AS (
    SELECT OwnerUserId, COUNT(*) AS TotalPosts
    FROM Posts
    GROUP BY OwnerUserId
),
UserReputation AS (
    SELECT Id AS UserId, Reputation, CreationDate, DisplayName, LastAccessDate
    FROM Users
    WHERE Reputation > 1000 -- Only include users with reputation greater than 1000
),
TopTags AS (
    SELECT tag.TagName, COUNT(p.Id) AS PostCount
    FROM Tags tag
    JOIN Posts p ON p.Tags LIKE '%' || tag.TagName || '%'
    GROUP BY tag.TagName
    HAVING COUNT(p.Id) > 100 -- Only consider tags with more than 100 posts
),
PostScores AS (
    SELECT p.Id AS PostId, p.Title, p.Score,
           ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS PostRank
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Selecting only questions
),
RecentActivity AS (
    SELECT u.Id AS UserId, u.DisplayName, COUNT(c.Id) AS CommentCount,
           MAX(c.CreationDate) AS LastCommentDate
    FROM Users u
    LEFT JOIN Comments c ON u.Id = c.UserId
    GROUP BY u.Id, u.DisplayName
    HAVING COUNT(c.Id) > 10 -- Users with more than 10 comments
)

SELECT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    ph.TotalPosts,
    ra.CommentCount,
    ra.LastCommentDate,
    tt.TagName,
    tt.PostCount,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.PostRank
FROM UserReputation u
JOIN UserPostCount ph ON u.UserId = ph.OwnerUserId
JOIN RecentActivity ra ON u.UserId = ra.UserId
JOIN TopTags tt ON tt.PostCount > 100
LEFT JOIN PostScores ps ON ps.PostRank = 1
WHERE u.CreationDate >= '2020-01-01' -- Filter for users created after 2020
ORDER BY u.Reputation DESC, ra.LastCommentDate DESC;
