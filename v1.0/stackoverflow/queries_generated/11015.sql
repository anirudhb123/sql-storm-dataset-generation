-- Performance Benchmarking SQL Query
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        SUM(V.VoteTypeId = 2) AS UpVoteCount,
        SUM(V.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.PostTypeId,
        COUNT(P.Id) AS TotalPosts,
        AVG(P.Score) AS AvgScore,
        AVG(P.ViewCount) AS AvgViewCount,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.PostTypeId
)
SELECT 
    UA.UserId,
    UA.Reputation,
    UA.PostCount,
    UA.CommentCount,
    UA.BadgeCount,
    UA.UpVoteCount,
    UA.DownVoteCount,
    PS.TotalPosts,
    PS.AvgScore,
    PS.AvgViewCount,
    PS.TotalComments
FROM 
    UserActivity UA
JOIN 
    PostStatistics PS ON UA.PostCount > 0
ORDER BY 
    UA.Reputation DESC, UA.PostCount DESC;
