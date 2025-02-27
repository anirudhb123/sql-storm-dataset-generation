-- Performance benchmarking query for the Stack Overflow schema
WITH PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        COUNT(CASE WHEN V.VoteTypeId IN (2, 3) THEN 1 END) AS VoteCount,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON P.OwnerUserId = B.UserId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount
)

SELECT 
    *,
    (SELECT COUNT(*) FROM PostHistory PH WHERE PH.PostId = PS.PostId) AS EditCount
FROM 
    PostStats PS
ORDER BY 
    ViewCount DESC
LIMIT 100;
