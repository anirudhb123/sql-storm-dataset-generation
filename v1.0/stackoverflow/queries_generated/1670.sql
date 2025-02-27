WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COALESCE(SUM(V.VoteTypeId = 2), 0) AS TotalUpvotes,
        COALESCE(SUM(V.VoteTypeId = 3), 0) AS TotalDownvotes
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.PostCount,
    U.CommentCount,
    U.UpvoteCount - U.DownvoteCount AS NetVotes,
    P.Title,
    P.CreationDate,
    P.ViewCount,
    P.Score,
    P.TotalComments,
    P.TotalUpvotes - P.TotalDownvotes AS NetPostVotes
FROM UserStats U
JOIN PostDetails P ON P.TotalComments > 10
ORDER BY U.Reputation DESC, P.Score DESC
LIMIT 50;

WITH RECURSIVE RelatedPosts AS (
    SELECT 
        PL.PostId,
        PL.RelatedPostId,
        1 AS Level
    FROM PostLinks PL
    WHERE PL.PostId IN (SELECT Id FROM Posts WHERE CreationDate >= NOW() - INTERVAL '1 year')

    UNION ALL

    SELECT 
        PL.PostId,
        PL.RelatedPostId,
        RP.Level + 1
    FROM PostLinks PL
    JOIN RelatedPosts RP ON PL.PostId = RP.RelatedPostId
    WHERE RP.Level < 3
)
SELECT 
    COUNT(*) AS TotalRelatedPosts, 
    MAX(Level) AS MaxRelationLevel
FROM RelatedPosts;
