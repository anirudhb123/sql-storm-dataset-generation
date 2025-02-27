WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(P.ViewCount) AS TotalViewCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY U.Id ORDER BY SUM(P.ViewCount) DESC) AS UserRank
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId 
    WHERE U.Reputation > 1000
    GROUP BY U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COALESCE(PH.CloseReasonId, 'Open') AS PostStatus,
        (SELECT STRING_AGG(T.TagName, ', ') 
         FROM Tags T 
         WHERE T.Id = ANY(string_to_array(P.Tags, '>'::varchar)::int[])) AS TagsList
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId AND PH.PostHistoryTypeId IN (10, 11)
    WHERE P.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.ViewCount,
        RANK() OVER (ORDER BY PS.Score DESC) AS RankScore
    FROM PostStatistics PS
    WHERE PS.PostStatus = 'Open'
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalViewCount,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    TP.Title AS TopPostTitle,
    TP.ViewCount AS TopPostViewCount,
    TP.RankScore
FROM UserActivity UA
LEFT JOIN TopPosts TP ON UA.UserId = (SELECT P.OwnerUserId FROM Posts P WHERE P.Id = TP.PostId LIMIT 1)
WHERE UA.UserRank <= 10
ORDER BY UA.TotalViewCount DESC, UA.DisplayName ASC;
