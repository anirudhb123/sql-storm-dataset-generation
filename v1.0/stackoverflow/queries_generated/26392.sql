WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN LATERAL (
        SELECT UNNEST(STRING_TO_ARRAY(P.Tags, '>')) AS TagName
    ) T ON true
    WHERE P.ViewCount >= 100
    GROUP BY P.Id, P.Title, P.Body, P.Score
),
PostHistoryDetails AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PHT.Name AS HistoryType,
        PH.UserId,
        PH.UserDisplayName,
        PH.Comment
    FROM PostHistory PH
    JOIN PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE PHT.Name IN ('Post Closed', 'Post Reopened', 'Post Deleted', 'Post Undeleted')
)
SELECT 
    U.DisplayName AS UserName,
    UB.BadgeCount,
    UB.BadgeNames,
    PP.Title AS PopularPostTitle,
    PP.Score AS PostScore,
    PP.CommentCount AS PopularPostCommentCount,
    PHD.CreationDate AS HistoryDate,
    PHD.HistoryType,
    PHD.Comment
FROM UserBadges UB
JOIN Users U ON U.Id = UB.UserId
JOIN PopularPosts PP ON PP.Score >= 10
LEFT JOIN PostHistoryDetails PHD ON PHD.UserId = U.Id
ORDER BY PP.Score DESC, UB.BadgeCount DESC, PHD.CreationDate DESC;
