
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        PostCount,
        QuestionCount,
        AnswerCount,
        TotalScore,
        TotalViews,
        @rank := @rank + 1 AS Rank
    FROM 
        UserPostStats, (SELECT @rank := 0) r
    ORDER BY 
        TotalScore DESC
),
BadgesCount AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalScore,
    tu.TotalViews,
    bc.BadgeCount,
    CASE 
        WHEN tu.Rank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    TopUsers tu
JOIN 
    BadgesCount bc ON tu.UserId = bc.UserId
WHERE 
    tu.PostCount > 0
ORDER BY 
    tu.TotalScore DESC,
    tu.PostCount DESC;
