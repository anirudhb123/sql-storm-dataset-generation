
WITH Benchmark AS (
    SELECT 
        P.Title,
        P.ViewCount,
        P.Score,
        U.Reputation AS OwnerReputation,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        P.CreationDate >= '2023-01-01' 
    GROUP BY 
        P.Title, P.ViewCount, P.Score, U.Reputation
)
SELECT 
    *,
    @row := IF(@prev_score = Score, @row + 1, 1) AS Rank,
    @prev_score := Score
FROM 
    Benchmark, (SELECT @row := 0, @prev_score := NULL) AS vars
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 10;
