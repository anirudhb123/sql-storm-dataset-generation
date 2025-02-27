
WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS TotalUpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS TotalDownVotes,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id 
    LEFT JOIN Badges b ON b.UserId = u.Id
    WHERE u.Reputation >= 1000
    GROUP BY u.Id, u.DisplayName, u.Reputation
), 
TopUsers AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        um.TotalUpVotes,
        um.TotalDownVotes,
        @row_num := @row_num + 1 AS UserRank
    FROM UserMetrics um, (SELECT @row_num := 0) AS r
    ORDER BY (um.TotalUpVotes - um.TotalDownVotes) DESC, um.Reputation DESC
)

SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.TotalUpVotes,
    tu.TotalDownVotes,
    CASE 
        WHEN tu.UserRank <= 10 THEN 'Top User'
        ELSE 'Regular User'
    END AS UserCategory,
    (SELECT 
        GROUP_CONCAT(DISTINCT t.TagName SEPARATOR ', ') 
     FROM Posts p
     JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', numbers.n), ',', -1)) AS tagName
           FROM (SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4) AS numbers
           WHERE CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= numbers.n - 1) AS tagArray ON tagArray.tagName IS NOT NULL
     JOIN Tags t ON t.TagName = tagArray.tagName
     WHERE p.OwnerUserId = tu.UserId) AS UserTags,
    (SELECT 
        COALESCE(GROUP_CONCAT(DISTINCT c.Text SEPARATOR '; '), 'No Comments') 
        FROM Comments c 
        WHERE c.UserId = tu.UserId) AS UserComments
FROM TopUsers tu
WHERE tu.UserId IN (
    SELECT DISTINCT u.Id 
    FROM Users u 
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id 
    WHERE p.CreationDate >= NOW() - INTERVAL 1 YEAR
)
ORDER BY tu.UserRank
LIMIT 50;
