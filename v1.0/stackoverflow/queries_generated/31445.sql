WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank,
        COUNT(DISTINCT C.Id) OVER (PARTITION BY P.Id) AS CommentCount
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
),

ClosedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.UserId,
        PH.Comment,
        P.Title
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    WHERE 
        PH.PostHistoryTypeId = 10
),

TagStats AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS TotalPosts,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews
    FROM 
        Tags T 
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
)

SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.Score,
    RP.CommentCount,
    CPH.CreationDate AS ClosedDate,
    CPH.Comment AS ClosureReason,
    TS.TagName,
    TS.TotalPosts,
    TS.TotalViews
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosedPostHistory CPH ON RP.PostId = CPH.PostId
LEFT JOIN 
    TagStats TS ON RP.Title LIKE '%' || TS.TagName || '%'
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC,
    RP.CommentCount DESC;
