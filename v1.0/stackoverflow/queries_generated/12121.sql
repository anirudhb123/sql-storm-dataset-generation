-- Performance benchmarking query to analyze user activity, post interactions, and vote trends

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(V.CreationDate IS NOT NULL) AS TotalVotes,
        SUM(P.ViewCount) AS TotalViews,
        SUM(CASE WHEN P.CreationDate > CURRENT_TIMESTAMP - INTERVAL '1 month' THEN 1 ELSE 0 END) AS PostsLastMonth
    FROM 
        Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),
PostTypesStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostsCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM 
        Posts P
    INNER JOIN PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY PT.Name
),
VoteStats AS (
    SELECT 
        VT.Name AS VoteType,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    INNER JOIN VoteTypes VT ON V.VoteTypeId = VT.Id
    GROUP BY VT.Name
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    U.TotalVotes,
    U.TotalViews,
    U.PostsLastMonth,
    PTS.PostType,
    PTS.PostsCount,
    PTS.TotalViews AS PostTypeTotalViews,
    PTS.AvgScore,
    VS.VoteType,
    VS.VoteCount
FROM 
    UserActivity U
    FULL OUTER JOIN PostTypesStats PTS ON TRUE
    FULL OUTER JOIN VoteStats VS ON TRUE
ORDER BY 
    U.TotalPosts DESC, PTS.PostsCount DESC, VS.VoteCount DESC;
