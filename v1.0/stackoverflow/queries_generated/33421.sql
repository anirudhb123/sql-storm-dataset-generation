WITH RECURSIVE UserRankings AS (
    SELECT Id, DisplayName, Reputation, CreationDate, LastAccessDate, 
           ROW_NUMBER() OVER (ORDER BY Reputation DESC) as Rank
    FROM Users
    WHERE Reputation > 0
),
PopularTags AS (
    SELECT Tags.TagName, COUNT(*) AS TagCount
    FROM Posts
    CROSS APPLY STRING_SPLIT(SUBSTRING(Tags, 2, LEN(Tags) - 2), '><') AS Tags 
    GROUP BY Tags.TagName
),
ActivePosts AS (
    SELECT P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, 
           P.OwnerUserId, U.DisplayName AS OwnerName,
           COALESCE(COUNT(C.Id), 0) AS CommentCount,
           COALESCE(SUM(V.VoteTypeId = 2), 0) AS UpVotes,  -- Count of UpVotes
           COALESCE(SUM(V.VoteTypeId = 3), 0) AS DownVotes  -- Count of DownVotes
    FROM Posts P
    LEFT JOIN Users U ON P.OwnerUserId = U.Id
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    WHERE P.CreationDate > DATEADD(MONTH, -6, GETDATE())
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score, P.ViewCount, P.OwnerUserId, U.DisplayName
),
PostsWithHistory AS (
    SELECT PH.PostId, 
           MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosedDate,
           MAX(CASE WHEN PH.PostHistoryTypeId = 19 THEN PH.CreationDate END) AS ProtectedDate
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT A.Id AS PostId, 
       A.Title, 
       A.CreationDate AS PostCreationDate,
       A.OwnerName, 
       A.Score,
       A.ViewCount, 
       TH.TagName,
       TH.TagCount,
       COALESCE(PH.ClosedDate, 'Open') AS Status,
       PH.ProtectedDate IS NOT NULL AS IsProtected,
       R.Rank AS UserRank,
       A.CommentCount,
       A.UpVotes,
       A.DownVotes
FROM ActivePosts A
LEFT JOIN PopularTags TH ON TH.TagName = (SELECT TOP 1 TagName FROM PopularTags ORDER BY TagCount DESC)
LEFT JOIN PostsWithHistory PH ON A.Id = PH.PostId
INNER JOIN UserRankings R ON A.OwnerUserId = R.Id
WHERE A.ViewCount >= 1000 
  AND A.Score BETWEEN 5 AND 100
ORDER BY A.Score DESC, A.ViewCount DESC;
