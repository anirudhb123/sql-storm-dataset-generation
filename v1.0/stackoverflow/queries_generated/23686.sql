WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Votes V ON V.UserId = U.Id
    WHERE U.Reputation > 0
    GROUP BY U.Id
),
TagPerformance AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostsWithTag,
        AVG(COALESCE(P.ViewCount, 0)) AS AvgViewCount,
        MAX(P.CreationDate) AS MostRecentPostDate
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
),
PostInfluence AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        COALESCE(V.TotalUpVotes, 0) AS UpVotes,
        COALESCE(V.TotalDownVotes, 0) AS DownVotes,
        P.ViewCount,
        CASE 
            WHEN P.Score > 0 THEN 'Positive Influence'
            WHEN P.Score < 0 THEN 'Negative Influence'
            ELSE 'Neutral'
        END AS InfluenceType
    FROM Posts P
    LEFT JOIN (
        SELECT 
            PostId,
            SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
            SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
        FROM Votes
        GROUP BY PostId
    ) V ON P.Id = V.PostId
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.TotalPosts,
    UA.TotalComments,
    TP.TagName,
    TP.PostsWithTag,
    TP.AvgViewCount,
    PI.PostId,
    PI.UpVotes,
    PI.DownVotes,
    PI.ViewCount,
    PI.InfluenceType,
    CASE 
        WHEN UA.TotalPosts > 100 AND UA.Reputation > 1000 THEN 'High Engagement'
        WHEN UA.TotalPosts BETWEEN 50 AND 100 AND UA.Reputation > 500 THEN 'Moderate Engagement'
        ELSE 'Low Engagement'
    END AS EngagementLevel
FROM UserActivity UA
LEFT JOIN TagPerformance TP ON TP.PostsWithTag > 5
LEFT JOIN PostInfluence PI ON PI.OwnerUserId = UA.UserId
ORDER BY UA.Reputation DESC, TP.AvgViewCount DESC
LIMIT 20 OFFSET 0;

