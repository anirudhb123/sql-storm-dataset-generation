WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC, P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1   -- Only questions
        AND P.Score > 10   -- Filters to highly ranked questions
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(TRIM(TAG.TagName), ', ') AS TagList
    FROM 
        Posts P
    CROSS JOIN LATERAL 
        (SELECT UNNEST(string_to_array(SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2), '><')) AS TagName) AS TAG
    GROUP BY 
        P.Id
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
        PH.PostHistoryTypeId = 10  -- Post Closed
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate as QuestionDate,
    RP.OwnerDisplayName,
    RP.ViewCount,
    RP.Score,
    PT.TagList,
    CP.ClosedDate,
    CP.CloseReason
FROM 
    RankedPosts RP
LEFT JOIN 
    PostTags PT ON RP.PostId = PT.PostId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.rn = 1   -- Get the top ranked post per user
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
