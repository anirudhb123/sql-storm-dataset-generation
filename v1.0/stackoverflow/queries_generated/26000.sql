WITH TagStatistics AS (
    SELECT 
        t.TagName, 
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ViewCount IS NOT NULL THEN p.ViewCount ELSE 0 END) AS TotalViews,
        AVG(p.Score) AS AverageScore
    FROM Tags t
    LEFT JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostsContributed
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        qr.UserId,
        SUM(qr.Reputation * ts.PostCount) AS WeightedReputation
    FROM UserReputation qr
    JOIN TagStatistics ts ON qr.PostsContributed > 0
    GROUP BY qr.UserId
    ORDER BY WeightedReputation DESC
    LIMIT 10
)
SELECT 
    t.TagName,
    ts.PostCount,
    ts.QuestionCount,
    ts.AnswerCount,
    ts.TotalViews,
    ts.AverageScore,
    tu.DisplayName AS TopUser,
    tu.WeightedReputation
FROM TagStatistics ts
JOIN TopUsers tu ON ts.PostCount > 0
ORDER BY ts.PostCount DESC, ts.AverageScore DESC;
