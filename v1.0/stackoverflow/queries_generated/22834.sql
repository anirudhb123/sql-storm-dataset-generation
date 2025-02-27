WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        CASE 
            WHEN U.UpVotes + U.DownVotes = 0 THEN 0
            ELSE ROUND(U.UpVotes::decimal / (U.UpVotes + U.DownVotes) * 100, 2)
        END AS UpVotePercentage,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.UserId AS EditorId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        RANK() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS EditRank,
        STRING_AGG(CASE WHEN PH.Comment IS NOT NULL THEN PH.Comment ELSE 'No comment' END, '; ') AS EditComments
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (4, 5, 6)  -- Edited Title, Body, Tags
    GROUP BY PH.PostId, PH.UserId, PH.PostHistoryTypeId, PH.CreationDate
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        MAX(PH.CreationDate) AS LastClosedDate,
        STRING_AGG(CASE WHEN PH.Comment IS NOT NULL THEN PH.Comment ELSE 'No reason provided' END, '; ') AS CloseReasons
    FROM Posts P
    INNER JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10  -- Post Closed
    GROUP BY P.Id, P.Title
),
UserPostActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS ActivePostCount,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id, U.DisplayName
)
SELECT 
    US.DisplayName,
    US.Reputation,
    US.UpVotePercentage,
    COALESCE(PH.EditComments, 'No edits') AS LastEditComments,
    COALESCE(CP.Title, 'No closed posts') AS ClosedPostTitle,
    COALESCE(CP.LastClosedDate, 'N/A') AS LastClosedDate,
    UPA.ActivePostCount,
    UPA.CommentCount,
    US.BadgeCount
FROM UserStats US
LEFT JOIN PostHistoryDetails PH ON US.UserId = PH.EditorId AND PH.EditRank = 1
LEFT JOIN ClosedPosts CP ON US.UserId = CP.PostId
LEFT JOIN UserPostActivity UPA ON UPA.UserId = US.UserId
WHERE US.Reputation > (SELECT AVG(Reputation) FROM Users)  -- Only consider users above average reputation
ORDER BY US.Reputation DESC, US.UpVotePercentage DESC
LIMIT 50;

