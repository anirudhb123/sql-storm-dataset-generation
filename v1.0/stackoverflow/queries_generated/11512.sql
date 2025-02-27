-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.Reputation AS OwnerReputation,
        COALESCE(V.UpVotes, 0) AS UpVotes,
        COALESCE(V.DownVotes, 0) AS DownVotes,
        COUNT(C.ID) AS CommentCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        P.Id, U.Reputation, P.Title, P.CreationDate, P.ViewCount, P.Score
),
PostHistoryStats AS (
    SELECT 
        Ph.PostId,
        COUNT(*) AS EditCount,
        MAX(Ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory Ph
    WHERE 
        Ph.PostHistoryTypeId IN (4, 5, 6, 24)  -- Edit Title, Edit Body, Edit Tags, Suggested Edit Applied
    GROUP BY 
        Ph.PostId
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.ViewCount,
    PS.Score,
    PS.OwnerReputation,
    PS.UpVotes,
    PS.DownVotes,
    PS.CommentCount,
    PS.AnswerCount,
    COALESCE(PHS.EditCount, 0) AS EditCount,
    PHS.LastEditDate
FROM 
    PostStats PS
LEFT JOIN 
    PostHistoryStats PHS ON PS.PostId = PHS.PostId
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;  -- Limit to the top 100 posts based on score and view count for benchmarking
