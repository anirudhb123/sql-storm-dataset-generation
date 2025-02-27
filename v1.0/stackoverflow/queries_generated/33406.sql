WITH RECURSIVE UserReputation AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        1 AS Level
    FROM Users u
    WHERE u.Reputation IS NOT NULL

    UNION ALL

    SELECT 
        u.Id,
        u.Reputation,
        u.DisplayName,
        u.CreationDate,
        ur.Level + 1
    FROM Users u
    INNER JOIN UserReputation ur ON ur.Reputation < u.Reputation
),
TagStats AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        AVG(p.Score) AS AvgScore
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE CONCAT('%', t.TagName, '%')
    GROUP BY t.TagName
),
ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalPostViews
    FROM Users u
    JOIN Posts p ON u.Id = p.OwnerUserId 
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY u.Id, u.DisplayName
),
RecentVotes AS (
    SELECT 
        p.Id AS PostId,
        COUNT(v.Id) AS VoteCount
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    WHERE v.CreationDate >= NOW() - INTERVAL '1 month'
    GROUP BY p.Id
)
SELECT 
    u.DisplayName,
    u.Reputation,
    ur.Level AS ReputationLevel,
    t.TagName,
    ts.PostCount,
    ts.TotalViews,
    ts.AvgScore,
    au.TotalPostViews,
    rv.VoteCount
FROM Users u
LEFT JOIN UserReputation ur ON u.Id = ur.UserId
LEFT JOIN TagStats ts ON ts.TagName IN (SELECT unnest(string_to_array(p.Tags, ',')) FROM Posts p WHERE p.OwnerUserId = u.Id)
LEFT JOIN ActiveUsers au ON au.Id = u.Id
LEFT JOIN RecentVotes rv ON rv.PostId IN (SELECT p.Id FROM Posts p WHERE p.OwnerUserId = u.Id)
WHERE u.Reputation > 1000
ORDER BY u.Reputation DESC, ts.TotalViews DESC
LIMIT 100;
