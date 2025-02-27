-- Performance Benchmarking SQL Query for StackOverflow Schema

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        COALESCE(MaxVote.VoteScore, 0) AS MaxVoteScore
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        (SELECT PostId, MAX(Score) AS VoteScore 
         FROM Votes 
         GROUP BY PostId) AS MaxVote ON P.Id = MaxVote.PostId
    WHERE 
        P.CreationDate >= '2023-01-01'  -- Filter for posts created in 2023
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostsCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.CommentCount,
    PS.AnswerCount,
    PS.MaxVoteScore,
    US.UserId,
    US.DisplayName,
    US.PostsCount,
    US.TotalUpVotes,
    US.TotalDownVotes
FROM 
    PostStats PS
JOIN 
    Users U ON PS.PostId = U.Id -- Assuming you want to join with Users
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
