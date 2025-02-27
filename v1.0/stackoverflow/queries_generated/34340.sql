WITH RECURSIVE PostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.ParentId,
        1 AS Level
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Select only questions

    UNION ALL

    SELECT 
        P2.Id AS PostId,
        P2.Title,
        P2.OwnerUserId,
        P2.ParentId,
        PH.Level + 1
    FROM Posts P2
    INNER JOIN PostHierarchy PH ON P2.ParentId = PH.PostId
)
, UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId
    WHERE U.Reputation > 100 -- Filter for active users
    GROUP BY U.Id, U.Reputation
), ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.Title,
        PH.Level,
        COUNT(PH2.PostId) AS AnswerCount
    FROM PostHierarchy PH
    LEFT JOIN Posts PH2 ON PH2.ParentId = PH.PostId
    WHERE PH.PostId IN (SELECT PostId FROM PostHistory WHERE PostHistoryTypeId = 10) -- Closed posts
    GROUP BY PH.PostId, PH.Title, PH.Level
)
SELECT 
    UA.UserId,
    UA.Reputation,
    UA.TotalPosts,
    UA.UpVotes,
    UA.DownVotes,
    UA.TotalComments,
    UA.TotalBadges,
    COALESCE(CP.AnswerCount, 0) AS ClosedPostAnswerCount,
    COUNT(DISTINCT CP.PostId) AS TotalClosedPosts
FROM UserActivity UA
LEFT JOIN ClosedPosts CP ON UA.UserId = CP.OwnerUserId
GROUP BY UA.UserId, UA.Reputation, UA.TotalPosts, UA.UpVotes, UA.DownVotes, UA.TotalComments, UA.TotalBadges, CP.AnswerCount
ORDER BY UA.Reputation DESC
LIMIT 100; -- Top 100 active users with closed posts
