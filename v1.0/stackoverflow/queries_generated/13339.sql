-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        U.Reputation AS OwnerReputation,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        SUM(V.VoteTypeId = 2) AS UpVotes,
        SUM(V.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        MAX(P.CreationDate) AS CreationDate,
        MAX(P.LastActivityDate) AS LastActivityDate
    FROM 
        Posts P
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND P.PostTypeId = 1 -- Answers to Questions
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, U.Reputation, P.PostTypeId
),
PostHistoryCount AS (
    SELECT 
        PostId,
        COUNT(*) AS HistoryCount
    FROM 
        PostHistory
    GROUP BY 
        PostId
)
SELECT 
    PS.PostId,
    PS.PostTypeId,
    PS.OwnerReputation,
    PS.AnswerCount,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.BadgeCount,
    PHC.HistoryCount,
    PS.CreationDate,
    PS.LastActivityDate
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryCount PHC ON PS.PostId = PHC.PostId
ORDER BY 
    PS.LastActivityDate DESC;
