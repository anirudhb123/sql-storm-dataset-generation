
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        U.DisplayName AS OwnerDisplayName,
        P.Score,
        P.ViewCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.OwnerUserId, U.DisplayName, P.Score, P.ViewCount
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.OwnerDisplayName,
    PS.Score,
    PS.ViewCount,
    COALESCE(PS.CommentCount, 0) AS CommentCount,
    COALESCE(PS.UpVotes, 0) AS UpVotes,
    COALESCE(PS.DownVotes, 0) AS DownVotes
FROM 
    PostStats PS
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
