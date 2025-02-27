WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.Id IS NOT NULL THEN 1 END) AS VoteCount,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate >= '2020-01-01'
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.OwnerDisplayName,
        RP.CommentCount,
        RP.VoteCount
    FROM RankedPosts RP
    WHERE RP.RankByScore <= 5
)
SELECT 
    TP.PostId,
    TP.Title,
    TP.CreationDate,
    TP.Score,
    TP.OwnerDisplayName,
    TP.CommentCount,
    TP.VoteCount,
    MH.TypeName AS PostHistoryType,
    PH.CreationDate AS HistoryCreationDate
FROM TopPosts TP
LEFT JOIN PostHistory PH ON TP.PostId = PH.PostId
LEFT JOIN PostHistoryTypes MH ON PH.PostHistoryTypeId = MH.Id
WHERE PH.CreationDate IS NOT NULL
ORDER BY TP.CreationDate DESC, TP.Score DESC;
