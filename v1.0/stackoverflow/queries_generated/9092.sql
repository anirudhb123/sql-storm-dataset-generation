WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.Score > 0 THEN p.Score ELSE 0 END) AS TotalScore,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000
    GROUP BY u.Id
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS QuestionCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    WHERE p.PostTypeId = 1
    GROUP BY t.TagName
    ORDER BY QuestionCount DESC
    LIMIT 10
),
TopUsers AS (
    SELECT 
        us.UserId,
        us.DisplayName,
        us.Reputation,
        us.PostCount,
        us.TotalScore,
        us.BadgeCount,
        us.LastPostDate
    FROM UserStats us
    WHERE us.PostCount > 5
    ORDER BY us.Reputation DESC
    LIMIT 5
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.TotalScore,
    tu.BadgeCount,
    tu.LastPostDate,
    pt.TagName,
    pt.QuestionCount
FROM TopUsers tu
JOIN PopularTags pt ON pt.QuestionCount > 5
ORDER BY tu.Reputation DESC, pt.QuestionCount DESC;
