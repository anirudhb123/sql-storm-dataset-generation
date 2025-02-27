
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 1 THEN P.Id END) AS QuestionCount,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes - Downvotes AS NetVotes,
        @userRank := @userRank + 1 AS UserRank
    FROM UserStatistics, (SELECT @userRank := 0) AS r
    ORDER BY Upvotes - Downvotes DESC
),
RecentActivities AS (
    SELECT 
        PH.UserId,
        PH.PostId,
        PH.CreationDate,
        PH.Comment,
        P.Title,
        @activityRank := IF(@prevUserId = PH.UserId, @activityRank + 1, 1) AS ActivityRank,
        @prevUserId := PH.UserId
    FROM PostHistory PH, (SELECT @activityRank := 0, @prevUserId := NULL) AS r
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.CreationDate >= (NOW() - INTERVAL 30 DAY)
    ORDER BY PH.UserId, PH.CreationDate DESC
),
FilteredActivities AS (
    SELECT 
        RA.UserId,
        RA.PostId,
        RA.CreationDate,
        RA.Comment,
        RA.Title,
        U.DisplayName
    FROM RecentActivities RA
    JOIN Users U ON RA.UserId = U.Id
    WHERE ActivityRank <= 5
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.NetVotes,
    FA.Title,
    FA.Comment,
    FA.CreationDate
FROM TopUsers TU
LEFT JOIN FilteredActivities FA ON TU.UserId = FA.UserId
WHERE TU.Reputation > 100 OR FA.Comment IS NOT NULL
ORDER BY TU.UserRank, FA.CreationDate DESC
LIMIT 50;
