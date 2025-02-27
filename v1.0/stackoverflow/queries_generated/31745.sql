WITH RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    WHERE u.Reputation > 100
    GROUP BY u.Id, u.DisplayName, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        PostCount,
        QuestionCount,
        AnswerCount,
        LastPostDate,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM RecentUserActivity
    WHERE PostCount > 5
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        ph.UserId AS EditorUserId,
        ph.UserDisplayName AS EditorUserName,
        ph.CreationDate AS EditDate,
        p.Title,
        p.Body,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY ph.CreationDate DESC) AS EditRank
    FROM PostHistory ph
    INNER JOIN Posts p ON ph.PostId = p.Id
    WHERE ph.PostHistoryTypeId IN (4, 5) -- Edit Title and Edit Body
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.QuestionCount,
    tu.AnswerCount,
    COALESCE(phd.EditDate, 'No Edits') AS LastEditDate,
    COALESCE(phd.EditorUserName, 'N/A') AS LastEditor
FROM TopUsers tu
LEFT JOIN PostHistoryDetails phd ON tu.UserId = phd.EditorUserId AND phd.EditRank = 1
ORDER BY tu.Rank;
