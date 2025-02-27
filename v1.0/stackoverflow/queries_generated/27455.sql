WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.Tags ORDER BY P.Score DESC) AS TagRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId IN (1, 2) -- Only considering Questions (1) and Answers (2)
),

TaggedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.CreationDate,
        RP.ViewCount,
        RP.Score,
        RP.OwnerDisplayName,
        STRING_AGG(T.TagName, ', ') AS TagsList
    FROM 
        RankedPosts RP
    LEFT JOIN 
        LATERAL unnest(string_to_array(RP.Title, ' ')) AS Tags ON TRUE
    JOIN 
        Tags T ON T.TagName = Tags
    WHERE 
        RP.TagRank = 1 -- Only take the top ranked post per tag
    GROUP BY 
        RP.PostId, RP.Title, RP.Body, RP.CreationDate, RP.ViewCount, RP.Score, RP.OwnerDisplayName
),

ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        C.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
)

SELECT 
    TP.Title,
    TP.Body,
    TP.OwnerDisplayName,
    TP.ViewCount,
    TP.Score,
    COALESCE(CP.ClosedDate, 'Not Closed') AS PostStatusDate,
    COALESCE(CP.CloseReason, 'N/A') AS CloseReason,
    TP.TagsList
FROM 
    TaggedPosts TP
LEFT JOIN 
    ClosedPosts CP ON TP.PostId = CP.PostId
ORDER BY 
    TP.Score DESC, TP.ViewCount DESC
LIMIT 100;
