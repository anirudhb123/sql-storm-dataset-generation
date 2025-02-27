
WITH RECURSIVE UserBadgeCount AS (
    SELECT 
        U.Id AS UserId,
        COUNT(B.Id) AS BadgeCount,
        RANK() OVER (ORDER BY COUNT(B.Id) DESC) AS BadgeRank
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id
), 
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.OwnerUserId,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        SUM(CASE WHEN V.CreationDate IS NOT NULL THEN 1 ELSE 0 END) AS VoteCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (2, 3) 
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.Title, P.CreationDate, P.OwnerUserId, P.Score
), 
PostMetadata AS (
    SELECT 
        RP.PostId,
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.CommentCount,
        RP.VoteCount,
        U.DisplayName,
        U.Reputation,
        UB.BadgeCount
    FROM RecentPosts RP
    LEFT JOIN Users U ON RP.OwnerUserId = U.Id
    LEFT JOIN UserBadgeCount UB ON U.Id = UB.UserId
), 
PostsWithTag AS (
    SELECT 
        P.Id,
        P.Title,
        GROUP_CONCAT(T.TagName SEPARATOR ', ') AS Tags
    FROM Posts P
    LEFT JOIN (
        SELECT 
            P.Id, 
            SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', numbers.n), '<>', -1) TagName
        FROM 
            (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
             SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
             SELECT 9 UNION ALL SELECT 10) numbers
        INNER JOIN Posts P ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) >= numbers.n - 1
    ) T ON P.Id = T.Id
    GROUP BY P.Id
)
SELECT 
    PM.Title,
    PM.CreationDate,
    PM.Score,
    PM.CommentCount,
    PM.VoteCount,
    PM.DisplayName,
    PM.Reputation,
    PM.BadgeCount,
    PT.Tags
FROM PostMetadata PM
LEFT JOIN PostsWithTag PT ON PM.PostId = PT.Id
WHERE PM.Reputation IS NOT NULL 
      AND PM.VoteCount > 0 
      AND PM.BadgeCount > 0
ORDER BY PM.Score DESC, PM.CreationDate DESC
LIMIT 50;
