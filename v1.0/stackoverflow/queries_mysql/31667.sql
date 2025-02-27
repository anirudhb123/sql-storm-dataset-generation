
WITH RECURSIVE RecentPosts AS (
    SELECT Id, Title, CreationDate, OwnerUserId, Score, ViewCount
    FROM Posts
    WHERE CreationDate > '2024-10-01 12:34:56' - INTERVAL 30 DAY
    UNION ALL
    SELECT p.Id, p.Title, p.CreationDate, p.OwnerUserId, p.Score, p.ViewCount
    FROM Posts p
    INNER JOIN RecentPosts rp ON p.Id = rp.Id
),
VoteSummary AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostsCreated,
        COALESCE(SUM(vs.UpVotes - vs.DownVotes), 0) AS NetVotes
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN VoteSummary vs ON vs.PostId = p.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
    HAVING COUNT(DISTINCT p.Id) > 5
)
SELECT
    ra.UserId,
    ra.DisplayName,
    ra.Reputation,
    ra.PostsCreated,
    ra.NetVotes,
    p.Title,
    p.Score,
    p.ViewCount,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    GROUP_CONCAT(DISTINCT t.TagName) AS Tags
FROM UserActivity ra
JOIN Posts p ON ra.UserId = p.OwnerUserId
LEFT JOIN VoteSummary vs ON vs.PostId = p.Id
LEFT JOIN (
    SELECT
        t.TagName
    FROM Tags t
    JOIN (
        SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', numbers.n), '>', -1) AS TagName
        FROM (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
        WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) >= numbers.n - 1
    ) AS tag_array ON t.TagName = tag_array.TagName
) AS t ON TRUE
WHERE p.CreationDate > '2024-10-01 12:34:56' - INTERVAL 60 DAY
GROUP BY ra.UserId, ra.DisplayName, ra.Reputation, ra.PostsCreated, ra.NetVotes, p.Title, p.Score, p.ViewCount, vs.UpVotes, vs.DownVotes
ORDER BY ra.Reputation DESC, ra.NetVotes DESC
LIMIT 10;
