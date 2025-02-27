-- Performance benchmarking SQL query for Stack Overflow schema

WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(A.Id) AS AnswerCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    WHERE 
        P.PostTypeId = 1 -- Only considering Questions
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.ViewCount, P.Score
),
UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
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
    PS.UpVotes,
    PS.DownVotes,
    US.UserId,
    US.DisplayName AS UserDisplayName,
    US.BadgeCount,
    US.TotalUpVotes,
    US.TotalDownVotes
FROM 
    PostStats PS
JOIN 
    Users U ON PS.UserId = U.Id 
JOIN 
    UserStats US ON U.Id = US.UserId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC;
