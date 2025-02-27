-- Performance Benchmarking Query for Stack Overflow Schema

WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount
)

SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalBadges,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.Title AS PostTitle,
    P.CreationDate AS PostCreationDate,
    P.ViewCount AS PostViewCount,
    P.CommentCount AS PostCommentCount,
    P.TotalUpVotes AS PostUpVotes,
    P.TotalDownVotes AS PostDownVotes
FROM 
    UserMetrics U
JOIN 
    PostMetrics P ON U.UserId = P.PostId -- Adjust join condition as necessary
ORDER BY 
    U.Reputation DESC, 
    P.ViewCount DESC;
