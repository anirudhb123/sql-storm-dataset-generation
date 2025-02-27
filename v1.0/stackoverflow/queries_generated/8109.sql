WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        SUM(B.Class) AS TotalBadges
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostEngagement AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COALESCE(PH.UserId, -1) AS LastEditorId,
        MAX(PH.CreationDate) AS LastEditedOn
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE P.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, PH.UserId
)
SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    UA.TotalBadges,
    PE.PostId,
    PE.Title,
    PE.CreationDate,
    PE.Score,
    PE.ViewCount,
    PE.CommentCount,
    PE.LastEditorId,
    PE.LastEditedOn
FROM UserActivity UA
JOIN PostEngagement PE ON UA.UserId = PE.LastEditorId
ORDER BY UA.TotalPosts DESC, PE.Score DESC
LIMIT 100;
