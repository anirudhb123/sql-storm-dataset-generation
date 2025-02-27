WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS TotalBadges,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
), 
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        U.DisplayName AS OwnerDisplayName,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.Tags,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.PostTypeId = 1  -- Considering only questions
    ORDER BY P.Score DESC, P.CreationDate DESC
    LIMIT 100
), 
EngagementMetrics AS (
    SELECT 
        TP.PostId,
        TP.Title,
        TP.Score,
        TP.ViewCount,
        TP.CommentCount,
        UP.BadgeNames,
        UP.TotalBadges
    FROM TopPosts TP
    JOIN UserBadges UP ON UP.UserId = TP.OwnerUserId
)
SELECT 
    EM.PostId,
    EM.Title,
    EM.Score,
    EM.ViewCount,
    EM.CommentCount,
    EM.BadgeNames,
    EM.TotalBadges,
    (EM.ViewCount * 1.0 / NULLIF(EM.CommentCount, 0)) AS ViewToCommentRatio,
    (EM.Score * 1.0 / NULLIF(EM.TotalBadges, 0)) AS ScoreToBadgeRatio
FROM EngagementMetrics EM
ORDER BY ViewToCommentRatio DESC, ScoreToBadgeRatio DESC;

This query investigates the relationship between user achievements (badges) and their post engagement metrics (questions), providing an analysis of the effectiveness of badges in relation to the popularity and interaction of posts.
