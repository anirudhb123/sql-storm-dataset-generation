
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id, P.Title, P.Body, P.Score, P.ViewCount, P.CreationDate, U.DisplayName
),
FilteredPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.Body,
        RP.Score,
        RP.ViewCount,
        RP.CreationDate,
        RP.OwnerDisplayName,
        RP.CommentCount
    FROM 
        RankedPosts RP
    WHERE 
        RP.PostRank <= 5 AND RP.Score > 10 
),
TopTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Posts P
    CROSS JOIN 
        (SELECT DISTINCT value AS TagName FROM STRING_SPLIT(Tags, '><')) T
    GROUP BY 
        T.TagName
    ORDER BY 
        PostCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
)
SELECT 
    FP.PostId,
    FP.Title,
    FP.Body,
    FP.Score,
    FP.ViewCount,
    FP.CreationDate,
    FP.OwnerDisplayName,
    FP.CommentCount,
    TT.TagName
FROM 
    FilteredPosts FP
CROSS JOIN 
    TopTags TT
ORDER BY 
    FP.Score DESC, FP.CreationDate DESC;
