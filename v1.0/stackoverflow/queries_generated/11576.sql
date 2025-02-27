-- Performance Benchmarking Query
-- This query measures the time taken for retrieving popular questions, their related tags, and associated user reputation.

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
        P.PostTypeId = 1 -- Looking for questions
    ORDER BY 
        P.Score DESC
    LIMIT 100 -- Limit to top 100 popular questions
)

SELECT 
    PQ.PostId,
    PQ.Title,
    PQ.CreationDate,
    PQ.Score,
    PQ.ViewCount,
    PQ.OwnerReputation,
    string_agg(PQ.TagName, ', ') AS Tags
FROM 
    PopularQuestions PQ
GROUP BY 
    PQ.PostId, PQ.Title, PQ.CreationDate, PQ.Score, PQ.ViewCount, PQ.OwnerReputation
ORDER BY 
    PQ.Score DESC;
