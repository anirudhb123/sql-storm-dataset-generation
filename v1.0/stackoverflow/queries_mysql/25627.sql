
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        GROUP_CONCAT(DISTINCT T.TagName) AS Tags,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (ORDER BY P.Score DESC, P.CreationDate ASC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT DISTINCT TagName FROM Tags) T ON FIND_IN_SET(T.TagName, REPLACE(P.Tags, '>', ',')) > 0
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, U.DisplayName, P.Title, P.CreationDate, P.Score
),
TaggedPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryDate,
        COUNT(*) AS HistoryCount,
        GROUP_CONCAT(PHT.Name ORDER BY PHT.Name SEPARATOR ', ') AS HistoryTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId, PH.PostHistoryTypeId, PH.CreationDate
),
PopularPosts AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerDisplayName,
        RP.CreationDate,
        RP.Score,
        RP.Tags,
        RP.CommentCount,
        TH.HistoryTypes,
        TH.HistoryCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        TaggedPostHistory TH ON RP.PostId = TH.PostId
    WHERE 
        RP.Rank <= 10  
)

SELECT 
    PP.PostId,
    PP.Title,
    PP.OwnerDisplayName,
    PP.CreationDate,
    PP.Score,
    PP.Tags,
    PP.CommentCount,
    COALESCE(PP.HistoryTypes, 'No history') AS HistoryTypes,
    COALESCE(PP.HistoryCount, 0) AS HistoryActionCount
FROM 
    PopularPosts PP
ORDER BY 
    PP.Score DESC, PP.CreationDate ASC;
