WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 2 -- Upvote
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY P.Id
),
PostMetrics AS (
    SELECT 
        AP.PostId,
        AP.Title,
        AP.ViewCount,
        AP.CommentCount,
        AP.VoteCount,
        RU.DisplayName,
        RU.Reputation AS UserReputation,
        RANK() OVER (PARTITION BY AP.ViewCount ORDER BY AP.VoteCount DESC) AS VoteRank
    FROM ActivePosts AP
    JOIN RankedUsers RU ON AP.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
)
SELECT 
    PM.PostId,
    PM.Title,
    PM.ViewCount,
    PM.CommentCount,
    PM.VoteCount,
    PM.DisplayName AS AcceptedAnswerUser,
    PM.UserReputation,
    PM.VoteRank
FROM PostMetrics PM
WHERE PM.VoteCount > 0
ORDER BY PM.VoteCount DESC, PM.ViewCount DESC
LIMIT 10;
