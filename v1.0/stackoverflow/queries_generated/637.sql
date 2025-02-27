WITH RankedPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM P.CreationDate) ORDER BY P.Score DESC, P.ViewCount DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id 
    WHERE 
        P.PostTypeId = 1 
    AND 
        P.CreationDate >= CURRENT_DATE - INTERVAL '2 years'
),
PostStatistics AS (
    SELECT 
        RP.OwnerDisplayName,
        COUNT(DISTINCT RP.Id) AS TotalPosts,
        COALESCE(SUM(PH.PostHistoryTypeId = 10), 0) AS TotalClosed,
        COALESCE(SUM(PH.PostHistoryTypeId = 11), 0) AS TotalReopened,
        AVG(RP.Score) AS AvgScore,
        AVG(RP.ViewCount) AS AvgViewCount
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistory PH ON RP.Id = PH.PostId
    GROUP BY 
        RP.OwnerDisplayName
)
SELECT 
    PS.OwnerDisplayName,
    PS.TotalPosts,
    PS.TotalClosed,
    PS.TotalReopened,
    PS.AvgScore,
    PS.AvgViewCount
FROM 
    PostStatistics PS
WHERE 
    PS.TotalPosts > 0
ORDER BY 
    PS.AvgScore DESC, 
    PS.TotalPosts DESC
LIMIT 10;

-- Second Segment: Get highest-ranking post details (with additional joins)
SELECT 
    RP.Title AS PostTitle,
    RP.Score AS PostScore,
    RP.ViewCount AS PostViews,
    C.Text AS LatestComment,
    C.CreationDate AS CommentDate
FROM 
    RankedPosts RP
LEFT JOIN 
    Comments C ON RP.Id = C.PostId
WHERE 
    RP.Rank = 1 AND 
    C.CreationDate = (
        SELECT MAX(C2.CreationDate) 
        FROM Comments C2 
        WHERE C2.PostId = RP.Id
    )
ORDER BY 
    RP.CreationDate DESC
LIMIT 5;
