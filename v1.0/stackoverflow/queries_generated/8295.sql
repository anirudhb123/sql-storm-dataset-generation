WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(CASE WHEN p.PostTypeId = 1 AND ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS QuestionsClosed,
        SUM(CASE WHEN p.PostTypeId = 1 AND ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS QuestionsReopened,
        AVG(p.ViewCount) AS AverageQuestionViews,
        COUNT(DISTINCT b.Id) AS BadgesEarned
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        PostHistory ph ON ph.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
ActiveUsers AS (
    SELECT 
        UserId,
        DisplayName,
        QuestionsAsked,
        AnswersGiven,
        QuestionsClosed,
        QuestionsReopened,
        AverageQuestionViews,
        BadgesEarned,
        ROW_NUMBER() OVER (ORDER BY QuestionsAsked DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    UserId,
    DisplayName,
    QuestionsAsked,
    AnswersGiven,
    QuestionsClosed,
    QuestionsReopened,
    AverageQuestionViews,
    BadgesEarned,
    Rank
FROM 
    ActiveUsers
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
