WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        P.OwnerUserId,
        COUNT(C.Id) AS CommentCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount,
        SUM(P.Score) AS TotalScore
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
), UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount, 
        SUM(PS.CommentCount) AS TotalComments,
        SUM(PS.CloseCount) AS TotalClosedPosts,
        SUM(PS.ReopenCount) AS TotalReopenedPosts,
        SUM(PS.TotalScore) AS Points
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN PostStats PS ON P.Id = PS.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id
), FinalReport AS (
    SELECT 
        U.DisplayName,
        U.Reputation,
        U.BadgeCount,
        U.PostCount,
        U.TotalComments,
        U.TotalClosedPosts,
        U.TotalReopenedPosts,
        U.Points,
        CASE 
            WHEN U.PostCount = 0 THEN 0
            WHEN U.TotalClosedPosts > 0 THEN (U.TotalReopenedPosts * 100.0) / U.TotalClosedPosts 
            ELSE 0 
        END AS ReopenToCloseRatio,
        CASE 
            WHEN U.BadgeCount = 0 THEN 'No Badges'
            WHEN U.BadgeCount <= 5 THEN 'Beginner'
            WHEN U.BadgeCount <= 15 THEN 'Intermediate'
            ELSE 'Expert'
        END AS BadgeLevel
    FROM UserPostStats U
)

SELECT 
    FR.DisplayName,
    FR.Reputation,
    FR.BadgeCount,
    FR.PostCount,
    FR.TotalComments,
    FR.TotalClosedPosts,
    FR.TotalReopenedPosts,
    FR.Points,
    FR.ReopenToCloseRatio,
    FR.BadgeLevel
FROM FinalReport FR
WHERE FR.ReputationRank <= 10
ORDER BY FR.Reputation DESC, FR.Points DESC;
