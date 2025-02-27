WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvotesReceived,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvotesReceived,
        COUNT(DISTINCT P.Id) AS PostsCount,
        COUNT(DISTINCT C.Id) AS CommentsCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.Id
),
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpvotesReceived,
        DownvotesReceived,
        PostsCount,
        CommentsCount,
        RANK() OVER (ORDER BY Reputation DESC, UpvotesReceived DESC, PostsCount DESC) AS UserRank
    FROM UserStats
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        UpvotesReceived,
        DownvotesReceived,
        PostsCount,
        CommentsCount,
        UserRank
    FROM RankedUsers
    WHERE UserRank <= 10
),
PostInteractions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        U.DisplayName AS Author,
        COALESCE(PH.Comment, 'No history') AS PostHistoryComment,
        PH.CreationDate AS HistoryDate,
        PH.PostHistoryTypeId,
        CASE 
            WHEN PH.PostHistoryTypeId IN (10, 11, 12) THEN 'Closed/Reopened/Deleted'
            ELSE 'Edited/Other'
        END AS PostHistoryType
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    P.Title AS PostTitle,
    P.CreationDate AS PostDate,
    P.PostHistoryType,
    COUNT(PI.PostId) AS InteractionCount
FROM TopUsers TU
JOIN PostInteractions P ON TU.UserId = P.Author
LEFT JOIN PostInteractions PI ON P.PostId = PI.PostId
GROUP BY TU.UserId, TU.DisplayName, TU.Reputation, P.Title, P.CreationDate, P.PostHistoryType
ORDER BY TU.Reputation DESC, InteractionCount DESC;
