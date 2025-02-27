WITH UserStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        SUM(b.Class) AS TotalBadges,
        DATEDIFF(CURRENT_TIMESTAMP, MIN(u.CreationDate)) AS AccountAgeDays
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PopularQuestions AS (
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.ViewCount,
        p.Score,
        u.DisplayName AS AuthorName,
        ROW_NUMBER() OVER (ORDER BY p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.PostTypeId = 1
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalQuestions,
        TotalAnswers,
        TotalScore,
        TotalBadges,
        AccountAgeDays
    FROM 
        UserStats
    WHERE 
        TotalPosts > 5
    ORDER BY 
        TotalScore DESC
    LIMIT 10
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalQuestions,
    u.TotalAnswers,
    u.TotalScore,
    u.TotalBadges,
    u.AccountAgeDays,
    q.QuestionId,
    q.Title AS PopularQuestionTitle,
    q.ViewCount,
    q.Score AS QuestionScore
FROM 
    TopUsers u
LEFT JOIN 
    PopularQuestions q ON u.UserId = (
        SELECT 
            OwnerUserId 
        FROM 
            Posts 
        WHERE 
            PostTypeId = 1 
        ORDER BY 
            Score DESC 
        LIMIT 1
    )
ORDER BY 
    u.TotalScore DESC, 
    q.ViewCount DESC;
