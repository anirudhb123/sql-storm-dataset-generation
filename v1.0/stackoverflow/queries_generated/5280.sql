WITH PopularTags AS (
    SELECT TagName, COUNT(PostId) AS TagCount
    FROM Tags
    JOIN Posts ON Tags.Id = Posts.Id
    WHERE Posts.PostTypeId = 1  -- Only questions
    GROUP BY TagName
    HAVING COUNT(PostId) > 50
),
RecentUsers AS (
    SELECT Id, DisplayName, Reputation
    FROM Users
    WHERE CreationDate > NOW() - INTERVAL '1 year'
),
ActivePosts AS (
    SELECT p.Id AS PostId, p.Title, p.Score, p.ViewCount, p.CreationDate, u.DisplayName AS OwnerName
    FROM Posts p
    JOIN Users u ON p.OwnerUserId = u.Id
    WHERE p.LastActivityDate > NOW() - INTERVAL '30 days'
      AND p.PostTypeId IN (1, 2)  -- Questions and Answers
),
TopVotes AS (
    SELECT PostId, COUNT(*) AS TotalVotes
    FROM Votes
    GROUP BY PostId
    ORDER BY TotalVotes DESC
    LIMIT 10
)
SELECT 
    ap.PostId,
    ap.Title,
    ap.Score,
    ap.ViewCount,
    ap.CreationDate,
    ap.OwnerName,
    pt.TagName,
    rv.RecentUserCount,
    tv.TotalVotes
FROM ActivePosts ap
JOIN PopularTags pt ON ap.Title ILIKE '%' || pt.TagName || '%'
JOIN (
    SELECT COUNT(*) AS RecentUserCount
    FROM RecentUsers
) rv ON true
JOIN TopVotes tv ON ap.PostId = tv.PostId
ORDER BY ap.Score DESC, tv.TotalVotes DESC;
