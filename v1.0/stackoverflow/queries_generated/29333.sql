WITH UserScore AS (
    SELECT 
        U.Id AS UserId,
        COALESCE(SUM(VoteTypeId = 2) - SUM(VoteTypeId = 3), 0) AS NetVotes,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id
),
PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Tags,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount,
        MAX(H.CreationDate) AS LastEditDate,
        MAX(H.PostHistoryTypeId) AS LastActionType
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory H ON P.Id = H.PostId
    GROUP BY P.Id, P.Title, P.Body, P.Tags
),
TopPosts AS (
    SELECT
        PS.PostId,
        PS.Title,
        PS.Body,
        PS.Tags,
        PS.CommentCount,
        PS.VoteCount,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation,
        US.NetVotes AS OwnerNetVotes,
        PS.LastEditDate,
        PS.LastActionType
    FROM PostStats PS
    JOIN Posts P ON PS.PostId = P.Id
    JOIN Users U ON P.OwnerUserId = U.Id
    JOIN UserScore US ON U.Id = US.UserId
    ORDER BY PS.VoteCount DESC, PS.CommentCount DESC
    LIMIT 10
)
SELECT 
    TP.Title,
    TP.Body,
    TP.Tags,
    TP.CommentCount,
    TP.VoteCount,
    TP.OwnerDisplayName,
    TP.OwnerReputation,
    TP.OwnerNetVotes,
    CASE 
        WHEN TP.LastActionType = 10 THEN 'Closed'
        WHEN TP.LastActionType = 11 THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus
FROM TopPosts TP;
