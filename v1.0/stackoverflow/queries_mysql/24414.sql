
WITH UserReputation AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8  
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation, U.CreationDate
),
PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionsCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswersCount,
        AVG(TIMESTAMPDIFF(SECOND, P.CreationDate, CURRENT_TIMESTAMP) / 60) AS AvgPostAgeInMinutes
    FROM Posts P
    GROUP BY P.OwnerUserId
),
PostHistoryAnalysis AS (
    SELECT
        PH.UserId,
        COUNT(PH.Id) AS EditsCount,
        MAX(PH.CreationDate) AS LastEditedDate,
        MIN(PH.CreationDate) AS FirstEditedDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY PH.UserId
),
CombinedStats AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        COALESCE(UR.TotalBounty, 0) AS TotalBounty,
        COALESCE(UR.BadgeCount, 0) AS BadgeCount,
        COALESCE(PS.PostCount, 0) AS PostCount,
        COALESCE(PS.TotalViews, 0) AS TotalViews,
        COALESCE(PS.QuestionsCount, 0) AS QuestionsCount,
        COALESCE(PS.AnswersCount, 0) AS AnswersCount,
        COALESCE(PHA.EditsCount, 0) AS EditsCount,
        PHA.LastEditedDate,
        PHA.FirstEditedDate,
        @row_number := @row_number + 1 AS UserRank
    FROM Users U
    LEFT JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN PostHistoryAnalysis PHA ON U.Id = PHA.UserId,
    (SELECT @row_number := 0) AS rn
)
SELECT 
    Expect.DisplayName,
    Expect.Reputation,
    Expect.TotalBounty,
    Expect.BadgeCount,
    Expect.PostCount,
    Expect.TotalViews,
    Expect.QuestionsCount,
    Expect.AnswersCount,
    Expect.EditsCount,
    Expect.LastEditedDate,
    Expect.FirstEditedDate,
    Expect.UserRank
FROM CombinedStats Expect
WHERE Expect.TotalBounty > (SELECT AVG(TotalBounty) FROM CombinedStats)
ORDER BY Expect.UserRank
LIMIT 10 OFFSET 5;
