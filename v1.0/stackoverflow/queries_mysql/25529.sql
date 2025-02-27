
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
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
        TotalViews,
        TotalScore,
        @rankByScore := IF(@prevScore = TotalScore, @rankByScore, @rowNumber) AS RankByScore,
        @rowNumber := @rowNumber + 1,
        @prevScore := TotalScore
    FROM 
        UserPostStats,
        (SELECT @rankByScore := 0, @rowNumber := 1, @prevScore := NULL) AS vars
    ORDER BY 
        TotalScore DESC
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    tu.UserId,
    tu.DisplayName,
    tu.PostCount,
    tu.QuestionCount,
    tu.AnswerCount,
    tu.TotalViews,
    tu.TotalScore,
    ub.BadgeCount,
    ub.BadgeNames,
    CASE 
        WHEN tu.RankByScore <= 10 THEN 'Top 10 by Score'
        WHEN (SELECT COUNT(*) FROM TopUsers WHERE RankByScore <= 10 AND PostCount < tu.PostCount) < 10 THEN 'Top 10 by Posts'
        ELSE 'Regular Contributor'
    END AS ContributorType
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
ORDER BY 
    tu.TotalScore DESC, tu.PostCount DESC;
