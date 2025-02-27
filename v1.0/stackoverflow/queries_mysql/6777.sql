
WITH UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    WHERE u.Reputation > 1000 AND u.LastAccessDate > NOW() - INTERVAL 6 MONTH
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
TopUsers AS (
    SELECT
        UserId,
        DisplayName,
        Reputation,
        Views,
        PostCount,
        QuestionCount,
        AnswerCount,
        BadgeCount,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM UserStats
)
SELECT
    tu.DisplayName,
    tu.Reputation,
    tu.Views,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.BadgeCount,
    COALESCE(GROUP_CONCAT(DISTINCT t.TagName), '') AS TopTags
FROM TopUsers tu
LEFT JOIN (
    SELECT 
        p.OwnerUserId,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, ',', n.n), ',', -1) AS TagName
    FROM Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5 
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) n ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, ',', '')) >= n.n - 1
    WHERE p.Tags IS NOT NULL
) t ON tu.UserId = t.OwnerUserId
WHERE tu.ReputationRank <= 10
GROUP BY tu.UserId, tu.DisplayName, tu.Reputation, tu.Views, tu.PostCount, tu.QuestionCount, tu.AnswerCount, tu.BadgeCount
ORDER BY tu.Reputation DESC;
