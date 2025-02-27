WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id
),
QuestionMetrics AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalQuestions,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS ClosedQuestions
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.CreationDate > P.CreationDate
    WHERE P.PostTypeId = 1
    GROUP BY P.OwnerUserId
)

SELECT 
    U.DisplayName,
    US.Reputation,
    US.QuestionCount,
    US.AnswerCount,
    QM.TotalQuestions,
    QM.AvgScore,
    QM.TotalViews,
    QM.TotalAnswers,
    QM.ClosedQuestions,
    CASE 
        WHEN US.BadgeCount >= 10 THEN 'Veteran'
        WHEN US.BadgeCount >= 5 THEN 'Experienced'
        ELSE 'Novice' 
    END AS UserLevel
FROM UserStats US
JOIN QuestionMetrics QM ON US.UserId = QM.OwnerUserId
ORDER BY US.QuestionCount DESC, US.Reputation DESC;
