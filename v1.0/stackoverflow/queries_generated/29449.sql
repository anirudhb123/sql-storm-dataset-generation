WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(COALESCE(P.Score, 0)) AS AverageScore,
        ARRAY_AGG(DISTINCT U.DisplayName) AS UserDisplayNames
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        T.Count > 0
    GROUP BY 
        T.TagName
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS CloseCount,
        MAX(PH.CreationDate) AS LastCloseDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (10, 11) -- Close and Reopen events
    GROUP BY 
        PH.PostId
),
UsersWithBadges AS (
    SELECT 
        U.Id AS UserId,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadgeCount,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadgeCount,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
)
SELECT 
    TS.TagName,
    TS.PostCount,
    TS.QuestionCount,
    TS.AnswerCount,
    TS.AverageScore,
    TL.CloseCount AS TotalCloseEvents,
    TL.LastCloseDate AS MostRecentCloseEvent,
    UWB.UserId,
    UWB.GoldBadgeCount,
    UWB.SilverBadgeCount,
    UWB.BronzeBadgeCount,
    ARRAY_AGG(DISTINCT TS.UserDisplayNames) AS Contributors
FROM 
    TagStatistics TS
LEFT JOIN 
    CloseReasons TL ON TL.PostId IN (SELECT Id FROM Posts WHERE Tags LIKE '%' || TS.TagName || '%')
LEFT JOIN 
    UsersWithBadges UWB ON UWB.UserId IN (SELECT DISTINCT OwnerUserId FROM Posts WHERE Tags LIKE '%' || TS.TagName || '%')
GROUP BY 
    TS.TagName, TL.CloseCount, TL.LastCloseDate, UWB.UserId, UWB.GoldBadgeCount, UWB.SilverBadgeCount, UWB.BronzeBadgeCount
ORDER BY 
    TS.PostCount DESC;
