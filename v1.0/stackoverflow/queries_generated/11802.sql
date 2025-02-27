WITH Benchmark AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        COUNT(C.Id) AS CommentCount,
        COUNT(V.Id) AS VoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, U.DisplayName
)

SELECT 
    *,
    (SELECT COUNT(*) FROM Posts WHERE ParentId = PostId) AS AnswerCount
FROM 
    Benchmark
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;
