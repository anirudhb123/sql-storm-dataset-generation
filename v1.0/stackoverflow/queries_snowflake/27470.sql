
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Body, 
        U.DisplayName AS OwnerName, 
        P.CreationDate, 
        P.Score, 
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        LISTAGG(DISTINCT T.TagName, ', ') WITHIN GROUP (ORDER BY T.TagName) AS TagsList
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        LATERAL FLATTEN(input => SPLIT(P.Tags, '<>')) AS T ON TRUE
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate, P.Score
),
PostHistoryContent AS (
    SELECT 
        PH.PostId,
        LISTAGG(PH.CreationDate, ', ') AS RevisionDates,
        LISTAGG(PHT.Name, ', ') AS HistoryTypes,
        MAX(PH.CreationDate) AS LastModifiedDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
EnhancedPosts AS (
    SELECT 
        RP.*, 
        PHC.RevisionDates, 
        PHC.HistoryTypes,
        PHC.LastModifiedDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistoryContent PHC ON RP.PostId = PHC.PostId
)
SELECT 
    EP.PostId,
    EP.Title,
    EP.OwnerName,
    EP.CreationDate,
    EP.Score,
    EP.CommentCount,
    EP.TagsList,
    EP.RevisionDates,
    EP.HistoryTypes,
    EP.LastModifiedDate,
    CASE 
        WHEN EP.Score >= 10 THEN 'High Score'
        WHEN EP.Score BETWEEN 5 AND 9 THEN 'Moderate Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    EnhancedPosts EP
WHERE 
    EP.LastModifiedDate >= DATEADD(day, -30, '2024-10-01 12:34:56')  
ORDER BY 
    EP.Score DESC, 
    EP.CommentCount DESC;
