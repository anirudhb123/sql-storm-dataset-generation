WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN pt.Name = 'Answer' THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN pt.Name = 'Question' THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(b.Class) AS TotalBadgeClass,
        SUM(v.BountyAmount) AS TotalBounty
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        AnswerCount,
        QuestionCount,
        TotalBadgeClass,
        TotalBounty,
        RANK() OVER (ORDER BY PostCount DESC) AS PostRank,
        RANK() OVER (ORDER BY AnswerCount DESC) AS AnswerRank,
        RANK() OVER (ORDER BY TotalBounty DESC) AS BountyRank
    FROM UserStats
)
SELECT 
    UserId,
    DisplayName,
    PostCount,
    AnswerCount,
    QuestionCount,
    TotalBadgeClass,
    TotalBounty,
    PostRank,
    AnswerRank,
    BountyRank
FROM ActiveUsers
WHERE PostCount > 10
ORDER BY PostCount DESC, AnswerCount DESC;
