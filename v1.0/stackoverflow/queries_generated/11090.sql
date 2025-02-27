-- Performance benchmarking query for StackOverflow schema
-- This query aims to analyze the relationships and overall performance across various posts, users, votes, and comments

WITH PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate AS PostCreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Id AS OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 -- Considering only questions
    GROUP BY 
        P.Id, U.Id
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        SUM(V.VoteTypeId = 2) AS TotalUserUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalUserDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON V.UserId = U.Id
    GROUP BY 
        U.Id
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.PostCreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.TotalComments,
    PS.TotalUpVotes,
    PS.TotalDownVotes,
    US.UserId AS OwnerUserId,
    US.DisplayName AS OwnerDisplayName,
    US.TotalPosts AS UserTotalPosts,
    US.TotalUserUpVotes,
    US.TotalUserDownVotes
FROM 
    PostStatistics PS
JOIN 
    UserStatistics US ON PS.OwnerUserId = US.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC; -- Order by score and view count to determine the most successful posts
