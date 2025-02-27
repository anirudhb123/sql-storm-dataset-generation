WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    GROUP BY U.Id, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        QuestionCount,
        AnswerCount,
        DENSE_RANK() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM UserReputation
    WHERE Reputation > 1000
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        COUNT(CM.Id) AS CommentCount,
        COALESCE(MAX(V.CreationDate), P.CreationDate) AS LastInteractionDate
    FROM Posts P
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.ViewCount
),

ClosedPosts AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate AS ClosedDate, 
        C.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE PH.PostHistoryTypeId = 10
    AND PH.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
),
CombinedResults AS (
    SELECT 
        U.UserId,
        U.Reputation,
        PA.PostId,
        PA.Title,
        PA.ViewCount,
        PA.CommentCount,
        COALESCE(CP.ClosedDate, 'No Closure') AS ClosedDate,
        COALESCE(CP.CloseReason, 'N/A') AS CloseReason
    FROM TopUsers U
    JOIN PostAnalytics PA ON U.UserId = PA.OwnerUserId
    LEFT JOIN ClosedPosts CP ON PA.PostId = CP.PostId
)

SELECT 
    UserId,
    Reputation,
    PostId,
    Title,
    ViewCount,
    CommentCount,
    ClosedDate,
    CloseReason,
    CASE 
        WHEN ClosedDate = 'No Closure' THEN 'Active'
        ELSE 'Closed'
    END AS PostStatus
FROM CombinedResults
WHERE Reputation > 2000 
ORDER BY Reputation DESC, ViewCount DESC;
