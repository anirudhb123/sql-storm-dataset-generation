-- Performance benchmarking query to analyze users' activity on posts and their associated votes

WITH UserPostActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount, -- Count UpVotes and DownVotes
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount, -- Count of comments
        COUNT(*) AS TotalPosts
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    GROUP BY 
        U.Id, U.DisplayName, P.Id, P.Title, P.CreationDate
)

SELECT 
    U.DisplayName,
    U.Id AS UserId,
    COUNT(DISTINCT PA.PostId) AS PostsCreated,
    SUM(PA.VoteCount) AS TotalVotes,
    SUM(PA.CommentCount) AS TotalComments,
    MIN(PA.PostCreationDate) AS FirstPostDate,
    MAX(PA.PostCreationDate) AS LastPostDate
FROM 
    UserPostActivity PA
JOIN 
    Users U ON U.Id = PA.UserId
GROUP BY 
    U.Id, U.DisplayName
ORDER BY 
    TotalVotes DESC, PostsCreated DESC;
