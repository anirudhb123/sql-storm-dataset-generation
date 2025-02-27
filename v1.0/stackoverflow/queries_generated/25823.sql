WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.ViewCount) AS AvgViewCount,
        SUM(COALESCE(P.AnswerCount, 0)) AS TotalAnswers,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName
), EffectiveUserStats AS (
    SELECT 
        UPS.UserId,
        UPS.DisplayName,
        UPS.PostCount,
        UPS.TotalScore,
        UPS.AvgViewCount,
        UPS.TotalAnswers,
        UPS.QuestionCount,
        UPS.AnswerCount,
        ROW_NUMBER() OVER (ORDER BY UPS.TotalScore DESC) AS Rank
    FROM UserPostStats UPS
    WHERE UPS.PostCount > 0
)

SELECT 
    EUS.DisplayName,
    EUS.PostCount,
    EUS.TotalScore,
    EUS.AvgViewCount,
    EUS.TotalAnswers,
    EUS.QuestionCount,
    EUS.AnswerCount,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
     WHERE P.OwnerUserId = EUS.UserId) AS PopularTags
FROM EffectiveUserStats EUS
WHERE EUS.Rank <= 10
ORDER BY EUS.TotalScore DESC;

WITH RecentHistory AS (
    SELECT 
        PH.UserDisplayName,
        PH.PostId,
        COUNT(*) AS EditCount,
        MAX(PH.CreationDate) AS LastEditDate,
        STRING_AGG(PHT.Name, ', ') AS EditTypes
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PH.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY PH.UserDisplayName, PH.PostId
),
RecentPostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.LastEditDate,
        R.EditCount,
        R.LastEditDate AS LastModified,
        R.EditTypes
    FROM Posts P
    JOIN RecentHistory R ON P.Id = R.PostId
)

SELECT 
    RPD.Title,
    RPD.LastModified,
    RPD.EditCount,
    RPD.EditTypes,
    RPD.PostId,
    RPD.LastEditDate,
    UP.DisplayName AS Editor
FROM RecentPostDetails RPD
JOIN Users UP ON UP.Id = (SELECT UserId FROM PostHistory WHERE PostId = RPD.PostId ORDER BY CreationDate DESC LIMIT 1)
ORDER BY RPD.LastModified DESC
LIMIT 5;
