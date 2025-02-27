WITH UserBadges AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgesList
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(P.AnswerCount, 0) AS AnswerCount,
        COALESCE(P.FavoriteCount, 0) AS FavoriteCount,
        COALESCE(P.CommentCount, 0) AS CommentCount,
        P.Score,
        P.LastActivityDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS Rank,
        EXTRACT(DAY FROM AGE(NOW(), P.CreationDate)) AS AgeInDays
    FROM Posts P
    WHERE P.OwnerUserId IS NOT NULL
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS Closures,
        STRING_AGG(C.R.Name, ', ' ORDER BY C.R.Name) AS CloseReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes C ON PH.Comment::int = C.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Post Closed or Reopened
    GROUP BY PH.PostId
),
PostWithBadges AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.AnswerCount,
        PS.CommentCount,
        PS.FavoriteCount,
        PS.Score,
        PS.Rank,
        PS.AgeInDays,
        UB.BadgeCount,
        UB.BadgesList
    FROM PostStats PS
    LEFT JOIN UserBadges UB ON PS.OwnerUserId = UB.UserId
)
SELECT 
    PWB.PostId,
    PWB.Title,
    PWB.AnswerCount,
    PWB.CommentCount,
    PWB.FavoriteCount,
    PWB.Score,
    PWB.Rank,
    PWB.AgeInDays,
    COALESCE(CP.Closures, 0) AS Closures,
    CP.CloseReasons,
    CASE 
        WHEN PWB.BadgeCount > 0 THEN 'Has Badges: ' || PWB.BadgesList 
        ELSE 'No Badges'
    END AS BadgeInfo,
    CASE 
        WHEN PWB.Score IS NULL THEN 'Unscored Post'
        WHEN PWB.Score < 0 THEN 'Negative Score'
        ELSE 'Positive Score'
    END AS ScoreInfo
FROM PostWithBadges PWB
LEFT JOIN ClosedPosts CP ON PWB.PostId = CP.PostId
WHERE PWB.AgeInDays > 30
ORDER BY PWB.Score DESC NULLS LAST,
         PWB.Title ASC;
