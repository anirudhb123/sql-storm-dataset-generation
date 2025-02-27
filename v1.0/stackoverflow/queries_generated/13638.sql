-- Performance Benchmarking SQL Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PT.Name AS PostType,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT V.Id) AS TotalVotes,
        SUM(V.BountyAmount) AS TotalBounty
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, PT.Name
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments AS UserTotalComments,
    U.TotalBounty AS UserTotalBounty,
    P.PostId,
    P.Title AS PostTitle,
    P.PostType,
    P.TotalComments AS PostTotalComments,
    P.TotalVotes,
    P.TotalBounty AS PostTotalBounty
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.TotalVotes DESC;
