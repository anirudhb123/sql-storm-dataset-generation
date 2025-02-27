WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        1 AS Level
    FROM Users U
    WHERE U.Reputation > 1000

    UNION ALL

    SELECT 
        U.Id,
        U.Reputation,
        U.CreationDate,
        UR.Level + 1
    FROM Users U
    JOIN UserReputation UR ON U.Reputation > (UR.Reputation * 0.5)
    WHERE UR.Level < 5
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY P.Id, P.OwnerUserId
),
UserPosts AS (
    SELECT
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(PM.VoteCount) AS TotalVotes,
        SUM(PM.CommentCount) AS TotalComments
    FROM Users U
    JOIN Posts P ON U.Id = P.OwnerUserId
    JOIN PostMetrics PM ON PM.PostId = P.Id
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UP.UserId,
        UP.DisplayName,
        UP.TotalPosts,
        UP.TotalVotes,
        UP.TotalComments,
        R.Reputation
    FROM UserPosts UP
    JOIN UserReputation R ON UP.UserId = R.UserId
    WHERE UP.TotalPosts > 5
)
SELECT 
    TU.DisplayName,
    TU.TotalPosts,
    TU.TotalVotes,
    TU.TotalComments,
    TU.Reputation,
    CASE 
        WHEN TU.Reputation > 5000 THEN 'Expert'
        WHEN TU.Reputation BETWEEN 2000 AND 5000 THEN 'Experienced'
        ELSE 'Novice'
    END AS UserLevel
FROM TopUsers TU
ORDER BY TU.Reputation DESC;

WITH TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        SUM(CASE WHEN P.ClosedDate IS NOT NULL THEN 1 ELSE 0 END) AS ClosedPosts
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE '%' + T.TagName + '%'
    GROUP BY T.TagName
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.AvgScore,
    TS.ClosedPosts,
    CASE 
        WHEN TS.PostCount > 100 THEN 'Highly Popular'
        WHEN TS.PostCount BETWEEN 50 AND 100 THEN 'Moderately Popular'
        ELSE 'Less Popular'
    END AS Popularity
FROM TagStats TS
WHERE TS.ClosedPosts < 10
ORDER BY TS.AvgScore DESC;
