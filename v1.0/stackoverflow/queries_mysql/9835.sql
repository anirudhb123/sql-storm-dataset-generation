
WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.ViewCount > 100 THEN 1 ELSE 0 END) AS PopularPostCount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        AnswerCount,
        PopularPostCount,
        @rank := @rank + 1 AS Rank
    FROM UserStats, (SELECT @rank := 0) r
    ORDER BY Reputation DESC
),
RecentEdits AS (
    SELECT 
        ph.UserId,
        ph.PostId,
        ph.CreationDate,
        ph.Comment,
        @edit_rank := IF(@current_post = ph.PostId, @edit_rank + 1, 1) AS EditRank,
        @current_post := ph.PostId
    FROM PostHistory ph, (SELECT @edit_rank := 0, @current_post := NULL) r
    WHERE ph.PostHistoryTypeId IN (4, 5, 6) 
    ORDER BY ph.PostId, ph.CreationDate DESC
)
SELECT 
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.AnswerCount,
    tu.PopularPostCount,
    COUNT(re.PostId) AS RecentEditsCount,
    MAX(re.CreationDate) AS LastEditDate
FROM TopUsers tu
LEFT JOIN RecentEdits re ON tu.UserId = re.UserId AND re.EditRank = 1
WHERE tu.Rank <= 10
GROUP BY tu.UserId, tu.DisplayName, tu.Reputation, tu.PostCount, tu.AnswerCount, tu.PopularPostCount
ORDER BY tu.Reputation DESC;
