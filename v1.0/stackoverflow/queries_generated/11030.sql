-- Performance Benchmarking Query
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        U.CreationDate,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.Reputation, U.CreationDate
), PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        COALESCE(CLOSED.Type, 0) AS IsClosed,
        COUNT(DISTINCT PH.Id) AS EditCount,
        COUNT(DISTINCT V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        PostHistoryTypes CLOSED ON PH.PostHistoryTypeId IN (10, 11)  -- Closed/Reopened
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, CLOSED.Type
)
SELECT 
    U.UserId,
    U.Reputation,
    U.CreationDate,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.Title,
    P.CreationDate AS PostCreationDate,
    P.Score,
    P.ViewCount,
    P.AnswerCount,
    P.IsClosed,
    P.EditCount,
    P.VoteCount
FROM 
    UserStats U
JOIN 
    PostStats P ON U.UserId = P.PostId  -- Assuming we're matching Users to the Posts they authored
ORDER BY 
    U.Reputation DESC, P.Score DESC;
