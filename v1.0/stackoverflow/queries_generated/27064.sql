WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        P.CreationDate,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        B.Name AS BadgeName,
        RANK() OVER (PARTITION BY string_to_array(P.Tags, ',') ORDER BY P.ViewCount DESC) AS TagRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Badges B ON U.Id = B.UserId AND B.Class = 1 -- Gold badges
    WHERE 
        P.PostTypeId = 1 -- Questions only
        AND P.ViewCount > 1000 -- Only popular questions
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        C.Name AS Reason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
),
TopTaggedPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.ViewCount,
        RP.BadgeName,
        CP.Reason,
        ROW_NUMBER() OVER (PARTITION BY RP.TagRank ORDER BY RP.ViewCount DESC) AS RowNum
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
)
SELECT 
    TTP.Title,
    TTP.OwnerDisplayName,
    TTP.ViewCount,
    TTP.BadgeName,
    TTP.Reason
FROM 
    TopTaggedPosts TTP
WHERE 
    TTP.RowNum <= 5 -- Top 5 per tag
ORDER BY 
    TTP.ViewCount DESC;

