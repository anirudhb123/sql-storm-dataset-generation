WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation >= 1000  -- Consider users with at least 1000 reputation

    UNION ALL

    SELECT 
        U.Id,
        U.Reputation,
        UR.Level + 1
    FROM 
        Users U
    JOIN 
        UserReputation UR ON U.Reputation < UR.Reputation
    WHERE 
        U.Reputation >= 1000  -- Maintain the same threshold
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        DENSE_RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.Score > 10  -- Only consider posts with more than 10 votes
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(P.Score) AS TotalScore
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id
    HAVING 
        SUM(P.Score) > 50  -- Only consider users with total score greater than 50
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        POST.Title,
        PH.Comment,
        U.DisplayName AS UserName,
        PH.PostHistoryTypeId,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentEdit
    FROM 
        PostHistory PH
    JOIN 
        Posts POST ON PH.PostId = POST.Id
    JOIN 
        Users U ON PH.UserId = U.Id
),
ClosedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReason
    FROM 
        Posts P
    JOIN 
        PostHistory PH ON P.Id = PH.PostId
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId = 10  -- Post closed
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UP.ParticipationCount, 0) AS ParticipationCount,
    PP.Title AS PopularPostTitle,
    (
        SELECT STRING_AGG(CONCAT_WS(': ', P.Title, PH.Comment), '; ')
        FROM PostHistoryDetails PH
        JOIN Posts P ON PH.PostId = P.Id
        WHERE PH.RecentEdit <= 5 AND PH.PostId = PP.PostId
    ) AS RecentHistory,
    CP.CloseReason AS ClosedPostReason,
    CP.ClosedDate
FROM 
    Users U
LEFT JOIN 
    (SELECT UserId, COUNT(PostId) AS ParticipationCount 
     FROM Posts 
     GROUP BY UserId) UP ON U.Id = UP.UserId
LEFT JOIN PopularPosts PP ON U.Id = PP.OwnerUserId
LEFT JOIN ClosedPosts CP ON PP.PostId = CP.PostId
WHERE 
    U.Reputation > 2000  -- Filters Users based on Reputation
ORDER BY 
    U.Reputation DESC, PP.Score DESC
LIMIT 10;
