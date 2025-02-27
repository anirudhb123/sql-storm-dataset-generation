WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(COALESCE(C.CommentCount, 0)) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounties,
        SUM(V.BountyAmount) FILTER (WHERE V.BountyAmount IS NOT NULL) AS ActiveBounties
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
), ActiveBadges AS (
    SELECT 
        B.UserId, 
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
), HighScoreUsers AS (
    SELECT 
        UA.UserId, 
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS Rank
    FROM UserActivity UA
    JOIN Users U ON UA.UserId = U.Id
    WHERE UA.PostCount > 5
), TagStats AS (
    SELECT 
        T.TagName, 
        COUNT(P.Id) AS PostCount
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
), PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PHT.Name = 'Post Closed' THEN PH.CreationDate END) AS LastClosedDate,
        COUNT(*) FILTER (WHERE PH.PostHistoryTypeId = 10) AS CloseVotes
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY PH.PostId
)
SELECT 
    U.UserId,
    U.DisplayName,
    UB.BadgeCount,
    UB.BadgeNames,
    UA.PostCount,
    UA.QuestionCount,
    UA.AnswerCount,
    UA.TotalComments,
    UA.TotalBounties,
    UA.ActiveBounties,
    HSU.Reputation,
    HSU.Rank,
    T.TagName,
    TS.PostCount AS TagPostCount,
    PHS.LastClosedDate, 
    PHS.CloseVotes
FROM UserActivity UA
LEFT JOIN ActiveBadges UB ON UA.UserId = UB.UserId
LEFT JOIN HighScoreUsers HSU ON UA.UserId = HSU.UserId
LEFT JOIN TagStats TS ON TS.PostCount > 0
LEFT JOIN PostHistorySummary PHS ON PHS.PostId IN (
    SELECT Id FROM Posts WHERE OwnerUserId = UA.UserId
)
WHERE UA.PostCount > 0
ORDER BY HSU.Reputation DESC, UA.DisplayName;
