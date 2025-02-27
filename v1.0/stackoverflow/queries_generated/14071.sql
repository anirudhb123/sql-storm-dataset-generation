-- Performance benchmarking query for analyzing post scores, view counts, and user reputations.

WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.Reputation AS OwnerReputation,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only analyze questions
)

SELECT 
    RP.Rank,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerReputation
FROM 
    RankedPosts RP
WHERE 
    RP.Rank <= 100 -- Limit to top 100 posts for benchmarking
ORDER BY 
    RP.Rank;
