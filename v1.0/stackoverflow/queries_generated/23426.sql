WITH UserPostStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePosts,
        AVG(P.Score) AS AverageScore,
        ARRAY_AGG(DISTINCT T.TagName ORDER BY T.TagName) AS Tags
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        unnest(string_to_array(P.Tags, '><')) AS TagName ON TRUE
    LEFT JOIN 
        Tags T ON T.TagName = TagName
    GROUP BY 
        U.Id
), 
PostHistories AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount,
        MAX(PH.CreationDate) AS LastEditDate,
        MAX(PH.UserId) FILTER (WHERE PH.PostHistoryTypeId IN (4, 5)) AS LastEditorId,
        STRING_AGG(DISTINCT PH.Comment, ', ') AS Comments
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 12, 13, 14, 15)
    GROUP BY 
        PH.PostId
),
ModerationStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS ModerationCount,
        MAX(PH.CreationDate) AS LastModerationDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11, 14, 15) 
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    UPS.PostCount,
    UPS.PositivePosts,
    UPS.NegativePosts,
    UPS.AverageScore,
    PH.HistoryCount,
    PH.LastEditDate,
    U.LastAccessDate,
    MD.LastModerationDate,
    CASE 
        WHEN PH.HistoryCount > 0 THEN (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PH.PostId)
        ELSE 0 
    END AS CommentCount,
    COALESCE(UPS.Tags, '{}') AS TagList
FROM 
    UserPostStats UPS
LEFT JOIN 
    PostHistories PH ON UPS.UserId = PH.LastEditorId
LEFT JOIN 
    ModerationStats MD ON PH.PostId = MD.PostId
WHERE 
    UPS.PostCount > 0
ORDER BY 
    UPS.AverageScore DESC,
    UPS.PostCount DESC
LIMIT 50;

