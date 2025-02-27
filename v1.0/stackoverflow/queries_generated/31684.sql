WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankByScore,
        DENSE_RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.ViewCount DESC) AS RankByViews
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastClosedDate,
        STRING_AGG(CR.Name, ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CR ON PH.Comment::INT = CR.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY 
        PH.PostId
),
TopPostDetails AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.OwnerName,
        RP.RankByScore,
        RP.RankByViews,
        COALESCE(CP.LastClosedDate, 'No closure history') AS LastClosed,
        COALESCE(CP.CloseReasons, 'None') AS Reasons
    FROM 
        RankedPosts RP
    LEFT JOIN 
        ClosedPosts CP ON RP.PostId = CP.PostId
)

SELECT 
    TPD.PostId,
    TPD.Title,
    TPD.OwnerName,
    TPD.RankByScore,
    TPD.RankByViews,
    TPD.LastClosed,
    TPD.Reasons
FROM 
    TopPostDetails TPD
WHERE 
    TPD.RankByScore <= 5  -- Top 5 posts per type
ORDER BY 
    TPD.RankByScore, 
    TPD.RankByViews DESC;

-- This query retrieves the top-performing posts based on score and views for each post type,
-- along with closure history information, if applicable.
