-- Performance Benchmarking Query
WITH UsersStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes,
        SUM(CASE WHEN B.Id IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.OwnerUserId,
        COUNT(P.Id) AS PostsCreated,
        SUM(P.Score) AS TotalPostScore,
        AVG(P.ViewCount) AS AvgViewCount,
        AVG(P.AnswerCount) AS AvgAnswerCount
    FROM 
        Posts P
    GROUP BY 
        P.OwnerUserId
)

SELECT 
    U.DisplayName,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalBadges,
    PS.PostsCreated,
    PS.TotalPostScore,
    PS.AvgViewCount,
    PS.AvgAnswerCount
FROM 
    UsersStats U
LEFT JOIN 
    PostStats PS ON U.UserId = PS.OwnerUserId
ORDER BY 
    U.TotalPosts DESC, 
    U.TotalUpVotes DESC;
