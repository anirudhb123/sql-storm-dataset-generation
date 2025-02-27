WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges
    GROUP BY UserId
),
PostStats AS (
    SELECT 
        OwnerUserId,
        COUNT(CASE WHEN PostTypeId = 1 THEN 1 END) AS Questions,
        COUNT(CASE WHEN PostTypeId = 2 THEN 1 END) AS Answers,
        SUM(ViewCount) AS TotalViews,
        SUM(Score) AS TotalScore
    FROM Posts
    GROUP BY OwnerUserId
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(UBC.TotalBadges, 0) AS TotalBadges,
        COALESCE(PS.Questions, 0) AS TotalQuestions,
        COALESCE(PS.Answers, 0) AS TotalAnswers,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.TotalScore, 0) AS TotalScore,
        DENSE_RANK() OVER (ORDER BY COALESCE(PS.TotalViews, 0) DESC, 
                                  COALESCE(PS.TotalScore, 0) DESC) AS Rank
    FROM Users U
    LEFT JOIN UserBadgeCounts UBC ON U.Id = UBC.UserId
    LEFT JOIN PostStats PS ON U.Id = PS.OwnerUserId
    WHERE U.Reputation > 0
)
SELECT 
    UserId,
    DisplayName,
    TotalBadges,
    TotalQuestions,
    TotalAnswers,
    TotalViews,
    TotalScore,
    Rank
FROM TopUsers
WHERE Rank <= 10
ORDER BY Rank;

WITH RecursivePostHistory AS (
    SELECT 
        PH.PostId, 
        PH.PostHistoryTypeId, 
        PH.CreationDate, 
        ROW_NUMBER() OVER (PARTITION BY PostId ORDER BY CreationDate) AS RN
    FROM PostHistory PH 
    WHERE PH.PostHistoryTypeId IN (10, 11, 12, 13, 19) -- Filtering for Close and Reopen events only
),
RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PHC.EditCount,
        COALESCE(CASE WHEN RP1.PostHistoryTypeId = 10 THEN 'Closed' 
                      WHEN RP1.PostHistoryTypeId = 11 THEN 'Reopened'
                      ELSE NULL END, 'Inactive') AS CurrentState -- Interpret the latest state
    FROM Posts P
    LEFT JOIN (SELECT PostId, COUNT(*) AS EditCount
               FROM PostHistory 
               WHERE PostHistoryTypeId = 4
               GROUP BY PostId) PHC ON P.Id = PHC.PostId
    LEFT JOIN RecursivePostHistory RP1 ON P.Id = RP1.PostId
    WHERE RP1.RN = 1 -- Most recent action
)
SELECT 
    PostId, 
    Title,
    EditCount, 
    CurrentState
FROM RankedPosts
WHERE CurrentState IS NOT NULL
ORDER BY PostId;

SELECT 
    U.Id AS UserId,
    U.DisplayName,
    COUNT(DISTINCT C.Id) AS TotalComments,
    AVG(C.Score) AS AvgCommentScore,
    STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
FROM Users U
LEFT JOIN Comments C ON U.Id = C.UserId
LEFT JOIN Posts P ON C.PostId = P.Id
LEFT JOIN Tags T ON POSITION(T.TagName IN P.Tags) > 0 -- Check for tags in post's tags
WHERE U.Reputation > 1000
GROUP BY U.Id, U.DisplayName
HAVING COUNT(DISTINCT C.Id) > 5
ORDER BY AvgCommentScore DESC;
