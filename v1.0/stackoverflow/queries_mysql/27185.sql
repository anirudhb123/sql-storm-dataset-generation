
WITH TagCounts AS (
    SELECT SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
           COUNT(*) AS PostCount
    FROM Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL 
        SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL 
        SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE PostTypeId = 1 
    GROUP BY TagName
),

UserReputation AS (
    SELECT U.Id AS UserId, 
           U.DisplayName,
           COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty, 
           SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
           SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName
),

PostHistoryReveal AS (
    SELECT PH.PostId, 
           PH.UserDisplayName,
           PH.CreationDate,
           P.Title,
           P.Body,
           P.ViewCount,
           P.Score,
           P.AnswerCount,
           P.CommentCount,
           P.FavoriteCount,
           PH.Comment,
           P.LastActivityDate
    FROM PostHistory PH
    JOIN Posts P ON PH.PostId = P.Id
    WHERE PH.PostHistoryTypeId IN (10, 11, 12) 
    AND P.PostTypeId = 1
)

SELECT TC.TagName, 
       TC.PostCount, 
       UR.UserId, 
       UR.DisplayName,
       UR.TotalBounty,
       UR.UpvoteCount,
       UR.DownvoteCount,
       PH.PostId,
       PH.Title,
       PH.Body,
       PH.ViewCount,
       PH.Score,
       PH.AnswerCount,
       PH.CommentCount,
       PH.FavoriteCount,
       PH.CreationDate AS PostCreationDate,
       PH.LastActivityDate AS PostLastActivity
FROM TagCounts TC
JOIN PostHistoryReveal PH ON FIND_IN_SET(TC.TagName, REPLACE(SUBSTRING_INDEX(SUBSTRING_INDEX(PH.TAGS, '><', -1), '><', 1), '][', ',')) 
JOIN UserReputation UR ON PH.UserDisplayName = UR.DisplayName
ORDER BY TC.PostCount DESC, UR.TotalBounty DESC, PH.ViewCount DESC
LIMIT 100;
