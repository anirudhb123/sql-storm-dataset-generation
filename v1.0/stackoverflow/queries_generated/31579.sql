WITH RECURSIVE UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        0 AS ActivityScore,
        u.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY p.CreationDate DESC) AS PostRank
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE p.CreationDate IS NOT NULL

    UNION ALL

    SELECT 
        u.Id,
        u.DisplayName,
        u.Reputation,
        u.ActivityScore + COALESCE(vs.VoteCount, 0) AS ActivityScore,
        u.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY c.CreationDate DESC) AS PostRank
    FROM Users u
    JOIN UserActivity ua ON u.Id = ua.UserId
    LEFT JOIN (SELECT 
                    PostId,
                    COUNT(*) AS VoteCount 
                FROM Votes 
                WHERE CreationDate > ua.CreationDate
                GROUP BY PostId
                ) vs ON vs.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
    LEFT JOIN Comments c ON c.UserId = u.Id
    WHERE u.Reputation > 100
),

TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        SUM(ActivityScore) AS TotalActivityScore
    FROM UserActivity
    GROUP BY UserId, DisplayName, Reputation
    HAVING SUM(ActivityScore) > 10
    ORDER BY TotalActivityScore DESC
    LIMIT 10
),

TagSummary AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount,
        AVG(p.ViewCount) AS AvgViews
    FROM Tags t
    JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY t.TagName
    ORDER BY PostCount DESC
),

PostHistorySummary AS (
    SELECT 
        ph.UserId,
        p.Title,
        COUNT(ph.Id) AS EditCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM PostHistory ph
    JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5, 24)
    GROUP BY ph.UserId, p.Title
)

SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.Reputation,
    tu.TotalActivityScore,
    ts.TagName,
    ts.PostCount,
    ts.AvgViews,
    phs.EditCount,
    phs.LastEditDate
FROM TopUsers tu
LEFT JOIN TagSummary ts ON tu.UserId = (SELECT MIN(u.Id) FROM Users u WHERE u.Reputation > tu.Reputation)
LEFT JOIN PostHistorySummary phs ON phs.UserId = tu.UserId
ORDER BY tu.TotalActivityScore DESC, ts.PostCount DESC;
