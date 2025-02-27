WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(C.Id) AS CommentCount,
        COALESCE(PH.RevisionCount, 0) AS RevisionCount,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
        LEFT JOIN Users U ON P.OwnerUserId = U.Id
        LEFT JOIN Comments C ON P.Id = C.PostId
        LEFT JOIN (
            SELECT 
                PostId,
                COUNT(Id) AS RevisionCount
            FROM 
                PostHistory
            GROUP BY 
                PostId
        ) PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.Body, P.CreationDate, U.DisplayName, PH.RevisionCount
),

FilteredPosts AS (
    SELECT 
        RP.*,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        RankedPosts RP
        LEFT JOIN Posts_PG.Tags T ON T.Id = ANY(STRING_TO_ARRAY(RP.Tags, ',')::int[])
    GROUP BY 
        RP.PostId, RP.Title, RP.Body, RP.CreationDate, RP.OwnerDisplayName, RP.CommentCount, RP.RevisionCount
)

SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.CreationDate,
    FP.OwnerDisplayName,
    FP.CommentCount,
    FP.RevisionCount,
    FP.Tags,
    RANK() OVER (ORDER BY FP.CommentCount DESC, FP.RevisionCount DESC) AS PopularityRank
FROM 
    FilteredPosts FP
WHERE 
    FP.PostRank = 1
ORDER BY 
    PopularityRank ASC
LIMIT 100;
