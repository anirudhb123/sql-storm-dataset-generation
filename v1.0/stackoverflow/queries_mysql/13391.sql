
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        COALESCE(PH.UserId, U.Id) AS LastEditorId,
        COALESCE(PH.UserDisplayName, U.DisplayName) AS LastEditorName,
        PH.CreationDate AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, 
        U.Id, PH.UserId, PH.UserDisplayName, PH.CreationDate
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.CommentCount,
    PS.AnswerCount,
    PS.LastEditorId,
    PS.LastEditorName,
    PS.LastEditDate,
    @row_number := @row_number + 1 AS Ranking
FROM 
    PostStats PS, (SELECT @row_number := 0) AS r
ORDER BY 
    PS.Score DESC, 
    PS.ViewCount DESC
LIMIT 100;
