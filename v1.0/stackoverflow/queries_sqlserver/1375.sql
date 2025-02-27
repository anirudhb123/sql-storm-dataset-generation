
WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS Author,
        COUNT(Comments.Id) AS TotalComments,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments ON P.Id = Comments.PostId
    WHERE 
        P.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, U.DisplayName
),

ClosePostReasons AS (
    SELECT 
        PH.PostId,
        STRING_AGG(CRT.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CRT ON CAST(PH.Comment AS INT) = CRT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        PH.PostId
)

SELECT 
    RP.Id,
    RP.Title,
    RP.CreationDate,
    RP.Score,
    RP.Author,
    COALESCE(RP.TotalComments, 0) AS TotalComments,
    COALESCE(CPR.CloseReasons, 'No close reasons') AS CloseReasons
FROM 
    RankedPosts RP
LEFT JOIN 
    ClosePostReasons CPR ON RP.Id = CPR.PostId
WHERE 
    RP.Score > 10
ORDER BY 
    RP.Score DESC
OFFSET 0 ROWS FETCH NEXT 100 ROWS ONLY;
