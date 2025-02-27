
WITH PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        U.Reputation AS UserReputation,
        GROUP_CONCAT(T.TagName ORDER BY T.TagName SEPARATOR ', ') AS TagName
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId 
    LEFT JOIN 
        Tags T ON PL.RelatedPostId = T.Id 
    WHERE 
        P.CreationDate >= '2023-01-01'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.AnswerCount, P.CommentCount, U.Reputation
)
SELECT 
    PostId,
    Title,
    CreationDate,
    Score,
    ViewCount,
    AnswerCount,
    CommentCount,
    UserReputation,
    TagName
FROM 
    PostMetrics
ORDER BY 
    Score DESC, ViewCount DESC
LIMIT 100;
