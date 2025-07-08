
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Score,
        P.ViewCount,
        P.Title,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank,
        COUNT(CASE WHEN C.PostId IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownvoteCount
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Votes V ON V.PostId = P.Id
    WHERE 
        P.CreationDate >= to_timestamp('2024-10-01 12:34:56') - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Score, P.ViewCount, P.Title, P.CreationDate, P.PostTypeId
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.Score,
    RP.Rank,
    RP.CommentCount,
    RP.UpvoteCount,
    RP.DownvoteCount,
    COALESCE(B.Name, 'No Badge') AS BadgeName,
    CASE 
        WHEN RP.CommentCount = 0 THEN 'No Comments'
        ELSE 'Comments Available'
    END AS CommentStatus,
    CASE 
        WHEN RP.UpvoteCount > RP.DownvoteCount THEN 'Positive Sentiment'
        WHEN RP.UpvoteCount < RP.DownvoteCount THEN 'Negative Sentiment'
        ELSE 'Neutral Sentiment'
    END AS SentimentAnalysis
FROM 
    RankedPosts RP
LEFT JOIN 
    Badges B ON B.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)
WHERE 
    RP.Rank <= 5 
ORDER BY 
    RP.Score DESC, 
    RP.ViewCount DESC;
