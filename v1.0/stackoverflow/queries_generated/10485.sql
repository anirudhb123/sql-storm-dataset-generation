-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON C.UserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    LEFT JOIN 
        Badges B ON B.UserId = U.Id
    GROUP BY 
        U.Id, U.Reputation
),
PostStats AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AvgScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalBadges,
    P.PostType,
    P.PostCount,
    P.AvgScore,
    P.TotalViews
FROM 
    UserStats U
CROSS JOIN 
    PostStats P
ORDER BY 
    U.Reputation DESC, P.PostCount DESC;
