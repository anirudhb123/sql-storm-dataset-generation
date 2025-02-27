WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        U.Views,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN P.PostTypeId IN (1, 2) THEN P.Score ELSE 0 END), 0) AS TotalScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate, U.Views
),
BadgeStats AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
),
PostHistoryCTE AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PT.Name AS PostTypeName,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.UserId ORDER BY PH.CreationDate DESC) AS HistoryRank
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    JOIN Posts PT ON PH.PostId = PT.Id
    WHERE PHT.Name LIKE '%Edit%'
)
SELECT 
    US.UserId,
    US.DisplayName,
    US.Reputation,
    US.Views,
    BS.BadgeCount,
    BS.GoldBadges,
    BS.SilverBadges,
    BS.BronzeBadges,
    US.AnswerCount,
    US.QuestionCount,
    US.TotalScore,
    (SELECT COUNT(*) FROM Comments C WHERE C.UserId = US.UserId) AS CommentCount,
    (SELECT COUNT(*) FROM Votes V WHERE V.UserId = US.UserId AND V.VoteTypeId = 2) AS UpVotes
FROM UserStats US
LEFT JOIN BadgeStats BS ON US.UserId = BS.UserId
LEFT JOIN PostHistoryCTE PHC ON US.UserId = PHC.UserId AND PHC.HistoryRank = 1
WHERE US.Reputation > 1000
ORDER BY US.TotalScore DESC, US.Reputation DESC
FETCH FIRST 10 ROWS ONLY;
