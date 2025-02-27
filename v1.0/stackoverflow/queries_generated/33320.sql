WITH RecursiveTagHierarchy AS (
    SELECT Id AS TagId, TagName, 1 AS Depth
    FROM Tags
    WHERE IsModeratorOnly = 0
    UNION ALL
    SELECT t.Id, t.TagName, r.Depth + 1
    FROM Tags t
    JOIN RecursiveTagHierarchy r ON r.TagId = t.ExcerptPostId
),
UserScore AS (
    SELECT U.Id AS UserId, 
           U.DisplayName, 
           U.Reputation,
           COUNT(DISTINCT P.Id) AS PostCount,
           SUM(COALESCE(V.VoteTypeId = 2,0)) AS UpvoteCount,
           SUM(COALESCE(V.VoteTypeId = 3,0)) AS DownvoteCount,
           (SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) -
            SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END)) AS NetVote
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE U.Reputation > 1000
    GROUP BY U.Id
),
PostActivity AS (
    SELECT P.Id AS PostId, 
           P.Title, 
           U.DisplayName AS Owner,
           PH.CreationDate AS HistoryDate,
           PH.Comment,
           ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS ActivityRank
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE PH.PostHistoryTypeId IN (10, 11, 12)  -- Closed, Reopened, Deleted
),
PopularTags AS (
    SELECT TagId, COUNT(*) AS PostsCount
    FROM (
        SELECT DISTINCT T.Id AS TagId, P.Id AS PostId
        FROM Posts P
        JOIN RecursiveTagHierarchy T ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    ) AS TagsPosts
    GROUP BY TagId
    ORDER BY PostsCount DESC
    LIMIT 10
)
SELECT 
    U.DisplayName AS User,
    U.Reputation,
    U.PostCount,
    U.UpvoteCount,
    U.DownvoteCount,
    U.NetVote,
    PH.Title AS PostTitle,
    PH.Owner,
    PH.HistoryDate,
    PH.Comment,
    (SELECT STRING_AGG(T.TagName, ', ') 
     FROM Tags T 
     JOIN PostTags PT ON PT.TagId = T.Id 
     WHERE PT.PostId = PH.PostId) AS PostTags,
    (SELECT COUNT(*) FROM Comments C WHERE C.PostId = PH.PostId) AS CommentCount
FROM UserScore U
LEFT JOIN PostActivity PH ON U.UserId = PH.Owner
WHERE PH.ActivityRank = 1
AND EXISTS (SELECT 1 FROM PopularTags PT WHERE PT.TagId IN (SELECT TagId FROM PostsTags WHERE PostId = PH.PostId))
ORDER BY U.Reputation DESC, U.NetVote DESC;
