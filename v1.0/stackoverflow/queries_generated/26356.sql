WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId IN (10, 11) THEN 1 ELSE 0 END) AS CloseCount,
        SUM(CASE WHEN b.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount,
        SUM(v.BountyAmount) AS TotalBounty,
        MAX(u.CreationDate) AS AccountCreationDate
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
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
        BadgeCount,
        TotalBounty,
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM UserStatistics
    WHERE PostCount > 0
)
SELECT 
    tu.Rank,
    tu.DisplayName,
    tu.Reputation,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.BadgeCount,
    tu.TotalBounty,
    COALESCE(ROUND(100.0 * tu.AnswerCount / NULLIF(tu.QuestionCount, 0), 2), 0) AS AnswerRatio
FROM TopUsers tu
WHERE tu.Rank <= 10
ORDER BY tu.Rank;
