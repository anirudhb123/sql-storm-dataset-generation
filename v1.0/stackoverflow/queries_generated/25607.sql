WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.Score,
        P.ViewCount,
        STUFF((SELECT ', ' + T.TagName 
               FROM Tags T
               JOIN Posts P2 ON P2.Tags LIKE '%' + CAST(T.TagName AS varchar(35)) + '%'
               WHERE P2.Id = P.Id
               FOR XML PATH('')), 1, 2, '') AS TagsList
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Only Questions
    ORDER BY P.Score DESC, P.ViewCount DESC
    OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY
),
PostHistoryStats AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS EditCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 11 THEN 1 END) AS ReopenCount
    FROM PostHistory PH
    GROUP BY PH.PostId
),
UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(PH.EditCount, 0) AS TotalEdits,
        COALESCE(PH.CloseCount, 0) AS TotalClosures,
        COALESCE(PH.ReopenCount, 0) AS TotalReopens
    FROM Users U
    LEFT JOIN PostHistoryStats PH ON U.Id = PH.PostId
)
SELECT 
    UBD.UserId,
    UBD.DisplayName,
    UBD.GoldBadges,
    UBD.SilverBadges,
    UBD.BronzeBadges,
    PA.PostId,
    PA.Title,
    PA.Score,
    PA.ViewCount,
    PA.TagsList,
    UA.TotalEdits,
    UA.TotalClosures,
    UA.TotalReopens
FROM UserBadgeStats UBD
JOIN TopPosts PA ON UBD.UserId = PA.OwnerUserId
LEFT JOIN UserActivity UA ON UBD.UserId = UA.UserId
ORDER BY UBD.Reputation DESC, UBD.UserId;
