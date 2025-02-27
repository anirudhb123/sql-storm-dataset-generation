WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM Tags T
    JOIN Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY T.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
PostsWithHistories AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        PT.Name AS PostType,
        PH.CreationDate AS HistoryDate,
        PH.PostHistoryTypeId,
        PH.Comment
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    JOIN PostHistoryTypes PT ON PH.PostHistoryTypeId = PT.Id
    WHERE PT.Name LIKE '%Title%'
),
EngagementStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        COALESCE(SUM(V.CreationDate IS NOT NULL), 0) AS VoteCount,
        COUNT(P.Id) AS PostCount,
        COUNT(C.Id) AS CommentCount
    FROM UserStats U
    LEFT JOIN Posts P ON U.UserId = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY U.UserId, U.DisplayName
)
SELECT 
    U.DisplayName,
    U.UpVotes,
    U.DownVotes,
    U.PostCount,
    U.CommentCount,
    PWT.Title,
    PWT.PostType,
    PH.HistoryDate,
    PT.Name AS PostHistoryName,
    COALESCE(PTG.TagName, 'No Tags') AS MostPopularTag,
    COALESCE(PTG.PostCount, 0) AS PopularTagPostCount,
    E.VoteCount AS UserVoteCount,
    E.CommentCount AS UserCommentCount
FROM UserStats U
LEFT JOIN PostsWithHistories PWT ON U.UserId = PWT.OwnerUserId
LEFT JOIN PopularTags PTG ON PWT.PostId = PTG.PostCount
LEFT JOIN EngagementStats E ON U.UserId = E.UserId
JOIN PostHistoryTypes PT ON PWT.PostHistoryTypeId = PT.Id
WHERE U.Reputation > 100
ORDER BY U.DisplayName, U.PostCount DESC;
