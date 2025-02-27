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
    LEFT JOIN Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8  -- BountyStart votes
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id
),
PostStatistics AS (
    SELECT
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionsCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswersCount,
        AVG(DATEDIFF(MINUTE, P.CreationDate, GETDATE())) AS AvgPostAgeInMinutes
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
    WHERE PH.PostHistoryTypeId IN (4, 5, 6)  -- Edit Title, Edit Body, Edit Tags
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
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS UserRank
    FROM Users U
    LEFT JOIN UserReputation UR ON U.Id = UR.UserId
    LEFT JOIN PostStatistics PS ON U.Id = PS.OwnerUserId
    LEFT JOIN PostHistoryAnalysis PHA ON U.Id = PHA.UserId
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
OFFSET 5 ROWS FETCH NEXT 10 ROWS ONLY;

This SQL query utilizes the provided schema to create a comprehensive performance benchmark by evaluating user contributions and statistics related to posts, including various outer joins, common table expressions (CTEs), aggregates, and window functions. The query filters users based on their total bounty contributions and ranks them, providing insight into the active contributors in the context of the Stack Overflow platform.
