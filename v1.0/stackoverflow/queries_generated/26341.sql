WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2) ORDER BY P.CreationDate DESC) AS Rank,
        P.Tags
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    AND 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
TagStatistics AS (
    SELECT 
        SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2) AS Tag,
        COUNT(*) AS TagCount,
        SUM(P.Score) AS TotalScore,
        AVG(P.ViewCount) AS AverageViews
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 -- Only Questions
    GROUP BY 
        SUBSTRING(P.Tags, 2, LENGTH(P.Tags) - 2)
),
ClosedPostReasons AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        MAX(PH.CreationDate) AS LastCloseDate,
        CT.Name AS CloseReason
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment::int = CT.Id
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen events
    GROUP BY 
        PH.PostId, CT.Name
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.Score,
    RP.ViewCount,
    RP.OwnerDisplayName,
    TS.Tag,
    TS.TagCount,
    TS.TotalScore,
    TS.AverageViews,
    CPR.CloseCount,
    CPR.LastCloseDate,
    CPR.CloseReason
FROM 
    RankedPosts RP
LEFT JOIN 
    TagStatistics TS ON RP.Tags LIKE '%' || TS.Tag || '%' -- Matching posts with tag statistics
LEFT JOIN 
    ClosedPostReasons CPR ON RP.PostId = CPR.PostId 
WHERE 
    RP.Rank = 1 -- Get only the latest question per tag
ORDER BY 
    TS.TagCount DESC,
    RP.CreationDate DESC;
