WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COUNT(DISTINCT CASE WHEN P.PostTypeId = 2 THEN P.Id END) AS AnswerCount
    FROM Posts P
    GROUP BY P.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate, 
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.PostHistoryTypeId = 10
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(P.PostCount, 0) AS TotalPosts,
        COALESCE(P.TotalScore, 0) AS TotalScore,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COUNT(C.Id) AS ClosedPostsCount
    FROM Users U
    LEFT JOIN PostStats P ON U.Id = P.OwnerUserId
    LEFT JOIN ClosedPosts CP ON U.Id = CP.PostId  -- Correlated Join on Closed Posts
    LEFT JOIN Comments C ON C.UserId = U.Id
    GROUP BY U.Id, P.PostCount, P.TotalScore, P.AnswerCount
)

SELECT 
    U.DisplayName,
    U.Reputation,
    UA.TotalPosts,
    UA.TotalScore,
    UA.AnswerCount,
    UA.ClosedPostsCount,
    CASE 
        WHEN UA.ClosedPostsCount > 0 THEN 'Has Closed Posts' 
        ELSE 'No Closed Posts' 
    END AS ClosedPostStatus,
    CASE 
        WHEN U.LastAccessDate < CURRENT_TIMESTAMP - INTERVAL '1 year' THEN 'Inactive for over a year'
        ELSE 'Active'
    END AS ActivityStatus
FROM UserReputation U
JOIN UserActivity UA ON U.UserId = UA.UserId
WHERE U.Reputation > 1000
ORDER BY U.Reputation DESC, UA.TotalScore DESC
LIMIT 100;

