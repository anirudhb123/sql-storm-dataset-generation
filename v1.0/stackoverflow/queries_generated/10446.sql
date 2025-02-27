-- Performance benchmarking SQL query to analyze user engagement metrics

WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
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
        U.Id
)

SELECT 
    U.DisplayName,
    U.Reputation,
    UA.TotalPosts,
    UA.TotalComments,
    UA.UpVotes,
    UA.DownVotes,
    UA.TotalBadges
FROM 
    Users U
JOIN 
    UserActivity UA ON U.Id = UA.UserId
ORDER BY 
    UA.TotalPosts DESC, UA.TotalComments DESC;
