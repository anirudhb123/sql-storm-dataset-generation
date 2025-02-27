-- Performance Benchmarking Query

WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.VoteTypeId IN (2)) AS TotalUpVotes,
        SUM(V.VoteTypeId IN (3)) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id
),
TagStats AS (
    SELECT 
        T.TagName,
        SUM(P.ViewCount) AS TotalViews,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    LEFT JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id
)

SELECT 
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    T.TagName,
    T.TotalViews,
    T.PostCount,
    P.Title AS PostTitle,
    P.CommentCount,
    P.VoteCount
FROM 
    UserStats U
JOIN 
    TagStats T ON U.UserId = (SELECT OwnerUserId FROM Posts ORDER BY RANDOM() LIMIT 1)
JOIN 
    PostStats P ON U.TotalPosts > 0
ORDER BY 
    U.Reputation DESC,
    T.TotalViews DESC
LIMIT 100;
