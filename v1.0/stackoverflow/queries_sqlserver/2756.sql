
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        STRING_SPLIT(TRIM(BOTH '{}' FROM P.Tags), '><') AS Tag ON 1=1
    JOIN 
        Tags T ON T.TagName = Tag.value
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.Author,
    PT.Tags,
    COALESCE(CP.CloseCount, 0) AS CloseCount
FROM 
    RankedPosts RP
LEFT JOIN 
    PostTags PT ON RP.PostId = PT.PostId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;
