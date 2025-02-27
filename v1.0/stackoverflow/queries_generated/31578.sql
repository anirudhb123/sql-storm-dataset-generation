WITH RECURSIVE UserReputation AS (
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, 1 AS Level
    FROM Users u
    WHERE u.Reputation > 1000 -- Starting point: users with reputation greater than 1000

    UNION ALL

    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate, ur.Level + 1
    FROM Users u
    JOIN Votes v ON u.Id = v.UserId
    JOIN UserReputation ur ON v.PostId IN (
        SELECT p.Id 
        FROM Posts p 
        WHERE p.OwnerUserId = ur.Id
    )
    WHERE ur.Level < 5 -- Limit to 5 levels of reputation connections
)
, PostScoreWithTags AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.OwnerUserId,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM Posts p
    LEFT JOIN LATERAL STRING_TO_ARRAY(p.Tags, ',') AS arr(tag) ON TRUE
    LEFT JOIN Tags t ON t.TagName = TRIM(both '<>' from arr.tag)
    GROUP BY p.Id, p.Title, p.Score, p.OwnerUserId
)
, UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(p.Score) AS TotalScore,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.LastActivityDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName
)
SELECT 
    ur.DisplayName AS Reputation_User,
    ur.Reputation,
    ups.PostCount,
    ups.TotalScore,
    ups.FirstPostDate,
    ups.LastPostDate,
    ps.PostId,
    ps.Title,
    ps.Score,
    ps.Tags
FROM UserReputation ur
JOIN UserPostStats ups ON ur.Id = ups.UserId
JOIN PostScoreWithTags ps ON ps.OwnerUserId = ur.Id
WHERE ur.Reputation > 1500
ORDER BY ur.Reputation DESC, ups.TotalScore DESC
LIMIT 100;

-- This query retrieves a list of users with a reputation above 1500, their post statistics, 
-- and the corresponding posts they own. It highlights users with extensive interaction 
-- through posts while associating them with their tags and score, allowing for 
-- performance benchmarking of active users in the Stack Overflow community.
