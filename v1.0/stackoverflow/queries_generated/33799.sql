WITH RecursiveUserScores AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName, 
        U.Reputation,
        0 AS Score,
        U.CreationDate
    FROM Users U
    WHERE U.Reputation > 100

    UNION ALL

    SELECT 
        UP.UserId,
        U.DisplayName,
        UP.Reputation,
        RUS.Score + (UP.Score * 0.1) AS Score,
        U.CreationDate
    FROM Votes UP
    JOIN Users U ON UP.UserId = U.Id
    JOIN RecursiveUserScores RUS ON U.Id = RUS.UserId
    WHERE RUS.Score IS NOT NULL
),
UserPostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    GROUP BY P.OwnerUserId
),
PostHistoryDetails AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        P.Title,
        P.Body,
        P.OwnerDisplayName,
        MAX(PH.CreationDate) OVER (PARTITION BY PH.PostId) AS LastEditDate
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Editing title, body, or tags
),
ClosedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.ViewCount,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReason
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    JOIN CloseReasonTypes C ON PH.Comment = C.Id::varchar
    WHERE PH.PostHistoryTypeId = 10 
),
TotalUserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UPS.TotalPosts, 0) AS TotalPosts,
        COALESCE(UPS.TotalQuestions, 0) AS TotalQuestions,
        COALESCE(UPS.TotalAnswers, 0) AS TotalAnswers,
        COALESCE(UPS.TotalScore, 0) AS TotalScore,
        COALESCE(RUS.Score, 0) AS ReputationScore
    FROM Users U
    LEFT JOIN UserPostStats UPS ON U.Id = UPS.OwnerUserId
    LEFT JOIN RecursiveUserScores RUS ON U.Id = RUS.UserId
)
SELECT 
    TUS.DisplayName,
    TUS.TotalPosts,
    TUS.TotalQuestions,
    TUS.TotalAnswers,
    TUS.TotalScore,
    TUS.ReputationScore,
    COUNT(CP.Id) AS ClosedPostCount,
    STRING_AGG(DISTINCT PH.Title, ', ') AS EditedPosts
FROM TotalUserStats TUS
LEFT JOIN ClosedPosts CP ON TUS.UserId = CP.Id
LEFT JOIN PostHistoryDetails PH ON TUS.UserId = PH.UserId
GROUP BY 
    TUS.UserId,
    TUS.DisplayName,
    TUS.TotalPosts,
    TUS.TotalQuestions,
    TUS.TotalAnswers,
    TUS.TotalScore,
    TUS.ReputationScore
ORDER BY 
    TUS.ReputationScore DESC,
    TUS.TotalPosts DESC
LIMIT 50;
