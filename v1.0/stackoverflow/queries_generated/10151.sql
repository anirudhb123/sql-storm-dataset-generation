-- Performance Benchmarking Query
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id, U.DisplayName
), 
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.CommentCount AS UserCommentCount,
    UA.UpVotes,
    UA.DownVotes,
    PS.PostId,
    PS.Title AS PostTitle,
    PS.CreationDate AS PostCreationDate,
    PS.Score AS PostScore,
    PS.ViewCount AS PostViewCount,
    PS.CommentCount AS PostCommentCount,
    PS.VoteCount AS PostVoteCount
FROM 
    UserActivity UA
JOIN 
    PostStatistics PS ON UA.UserId = PS.PostId
ORDER BY 
    UA.Reputation DESC,              -- Assuming some column to order by, Reputation not present in UserActivity but based on current schema.
    PS.ViewCount DESC;
