
WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name ORDER BY B.Name SEPARATOR ', ') AS Badges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(CASE WHEN P.PostTypeId = 1 THEN 1 END) AS QuestionCount,
        COUNT(CASE WHEN P.PostTypeId = 2 THEN 1 END) AS AnswerCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AverageScore
    FROM Posts P
    GROUP BY P.OwnerUserId
), UserPostDetails AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UB.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.QuestionCount, 0) AS QuestionCount,
        COALESCE(PS.AnswerCount, 0) AS AnswerCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.AverageScore, 0) AS AverageScore
    FROM Users U
    LEFT JOIN UserBadges UB ON U.Id = UB.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
),
RankedUsers AS (
    SELECT 
        U.*,
        @rank := IF(@prevTotalViews = TotalViews, @rank, @rank + 1) AS Rank,
        @prevTotalViews := TotalViews
    FROM UserPostDetails U, (SELECT @rank := 0, @prevTotalViews := NULL) r
    WHERE QuestionCount > 0
    ORDER BY TotalViews DESC, AverageScore DESC
)
SELECT 
    R.UserId,
    R.DisplayName,
    R.BadgeCount,
    R.QuestionCount,
    R.AnswerCount,
    R.TotalViews,
    R.AverageScore,
    CASE 
        WHEN R.BadgeCount > 5 THEN 'Expert'
        WHEN R.BadgeCount BETWEEN 1 AND 5 THEN 'Novice'
        ELSE 'No Badges'
    END AS UserLevel
FROM RankedUsers R
WHERE R.Rank <= 10
ORDER BY R.Rank;
