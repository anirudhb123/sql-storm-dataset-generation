
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        @row_number := IF(@prev_post_type_id = P.PostTypeId, @row_number + 1, 1) AS Rank,
        @prev_post_type_id := P.PostTypeId
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    CROSS JOIN (SELECT @row_number := 0, @prev_post_type_id := NULL) AS init
    WHERE P.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, U.DisplayName
),
TopPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.ViewCount,
        RP.OwnerDisplayName,
        RP.TotalComments,
        RP.Upvotes,
        RP.Downvotes
    FROM RankedPosts RP
    WHERE RP.Rank <= 10
)
SELECT 
    TP.Title,
    TP.CreationDate,
    TP.OwnerDisplayName,
    TP.Score,
    TP.ViewCount,
    TP.TotalComments,
    TP.Upvotes,
    TP.Downvotes,
    CASE 
        WHEN TP.Upvotes >= TP.Downvotes THEN 'Positive Engagement'
        ELSE 'Negative Engagement'
    END AS EngagementType
FROM TopPosts TP
ORDER BY TP.Score DESC, TP.ViewCount DESC;
