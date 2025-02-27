-- Performance Benchmarking Query
WITH PostStats AS (
    SELECT
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(V.Id) AS VoteCount,
        COUNT(C.Id) AS CommentCount
    FROM
        Posts P
    JOIN
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN
        Votes V ON P.Id = V.PostId
    LEFT JOIN
        Comments C ON P.Id = C.PostId
    GROUP BY
        P.Id, U.DisplayName
),
PostHistoryStats AS (
    SELECT
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount,
        MAX(PH.CreationDate) AS LatestUpdate
    FROM
        PostHistory PH
    GROUP BY
        PH.PostId
)

SELECT
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.OwnerDisplayName,
    PS.VoteCount,
    PHS.HistoryCount,
    PHS.LatestUpdate
FROM
    PostStats PS
LEFT JOIN
    PostHistoryStats PHS ON PS.PostId = PHS.PostId
ORDER BY
    PS.Score DESC,
    PS.ViewCount DESC
LIMIT 100;  -- Limit to top 100 posts for performance comparison
