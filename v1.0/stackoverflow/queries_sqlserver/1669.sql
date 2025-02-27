
WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(ISNULL(P.Score, 0)) AS TotalScore,
        ROW_NUMBER() OVER (ORDER BY SUM(ISNULL(P.Score, 0)) DESC) AS Rank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
),
QuestionHistory AS (
    SELECT 
        PH.PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS ClosedCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenedCount
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE P.PostTypeId = 1
    GROUP BY PH.PostId
)
SELECT 
    UPS.UserId,
    UPS.DisplayName,
    UPS.TotalPosts,
    UPS.TotalQuestions,
    UPS.TotalAnswers,
    UPS.TotalScore,
    QH.ClosedCount,
    QH.ReopenedCount,
    UPS.TotalPosts - ISNULL(QH.ClosedCount, 0) AS ActivePosts
FROM UserPostStats UPS
LEFT JOIN QuestionHistory QH ON UPS.UserId = QH.PostId
WHERE UPS.TotalQuestions > 10
ORDER BY UPS.TotalScore DESC, ActivePosts DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
