
WITH RecentPosts AS (
    SELECT P.Id AS PostId, 
           P.Title,
           P.CreationDate,
           COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
           COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
           COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY P.Id, P.Title, P.CreationDate
),
PopularTags AS (
    SELECT T.TagName, 
           COUNT(*) AS UsageCount
    FROM Tags T
    JOIN Posts P ON FIND_IN_SET(T.Id, P.Tags)
    WHERE P.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY T.TagName
    ORDER BY UsageCount DESC
    LIMIT 5
),
UserBadges AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           COUNT(B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
    HAVING COUNT(B.Id) > 0
)
SELECT RP.PostId, 
       RP.Title, 
       RP.CreationDate, 
       RP.UpVotes, 
       RP.DownVotes, 
       RP.CommentCount, 
       PT.TagName, 
       UB.UserId, 
       UB.DisplayName AS UserWithBadges, 
       UB.BadgeCount
FROM RecentPosts RP
JOIN PopularTags PT ON RP.PostId IN (SELECT PostId FROM Posts WHERE Tags LIKE CONCAT('%', PT.TagName, '%'))
JOIN UserBadges UB ON RP.PostId = (SELECT OwnerUserId FROM Posts WHERE Id = RP.PostId)
ORDER BY RP.UpVotes DESC, RP.CreationDate DESC
LIMIT 10;
