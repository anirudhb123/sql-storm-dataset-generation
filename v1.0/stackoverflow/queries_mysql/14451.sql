
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        P.FavoriteCount,
        U.Reputation AS OwnerReputation,
        U.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS TotalComments,
        (SELECT COUNT(*) FROM Votes V WHERE V.PostId = P.Id) AS TotalVotes
    FROM
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)

SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.Score,
    PS.ViewCount,
    PS.AnswerCount,
    PS.CommentCount,
    PS.FavoriteCount,
    PS.OwnerReputation,
    PS.OwnerDisplayName,
    PS.TotalComments,
    PS.TotalVotes,
    RANK() OVER (ORDER BY PS.Score DESC, PS.ViewCount DESC) AS RankByScoreViewCount
FROM 
    PostStats PS
WHERE 
    PS.CreationDate >= NOW() - INTERVAL 1 YEAR
ORDER BY 
    PS.Score DESC, PS.ViewCount DESC
LIMIT 100;
