
WITH PopularQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        T.TagName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    JOIN 
        Tags T ON T.ExcerptPostId = P.Id
    WHERE 
        P.PostTypeId = 1 
    ORDER BY 
        P.Score DESC
    OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY
)

SELECT 
    PQ.PostId,
    PQ.Title,
    PQ.CreationDate,
    PQ.Score,
    PQ.ViewCount,
    PQ.OwnerReputation,
    STRING_AGG(PQ.TagName, ', ') AS Tags
FROM 
    PopularQuestions PQ
GROUP BY 
    PQ.PostId, PQ.Title, PQ.CreationDate, PQ.Score, PQ.ViewCount, PQ.OwnerReputation
ORDER BY 
    PQ.Score DESC;
