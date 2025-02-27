WITH RecursivePostHierarchy AS (
    SELECT 
        P.Id AS PostId,
        P.ParentId,
        0 AS Level
    FROM Posts P
    WHERE P.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        P.Id AS PostId, 
        P.ParentId,
        Level + 1
    FROM Posts P
    INNER JOIN RecursivePostHierarchy RPH ON P.ParentId = RPH.PostId
),
PostStats AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        SUM(COALESCE(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END, 0)) AS CloseReopenedCount,
        AVG(COALESCE(PH.CreationDate, CURDATE())) - P.CreationDate AS DaysSinceModification,
        COUNT(DISTINCT C.Id) AS CommentCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    GROUP BY P.Id
),
PostWithTags AS (
    SELECT 
        PS.Id,
        PS.Title,
        PS.CreationDate,
        PS.UpVotes,
        PS.DownVotes,
        PS.CloseReopenedCount,
        PS.DaysSinceModification,
        PS.CommentCount,
        T.TagName
    FROM PostStats PS
    LEFT JOIN Tags T ON PS.Id = T.ExcerptPostId
),
RankedPosts AS (
    SELECT 
        *,
        ROW_NUMBER() OVER (PARTITION BY TagName ORDER BY UpVotes DESC) AS PostRank
    FROM PostWithTags
)
SELECT 
    R.TagName,
    R.Title,
    R.UpVotes,
    R.DownVotes,
    R.CommentCount,
    R.DaysSinceModification,
    R.CloseReopenedCount,
    COUNT(*) OVER (PARTITION BY R.TagName) AS TotalPostsPerTag
FROM RankedPosts R
WHERE R.PostRank <= 5
ORDER BY R.TagName, R.UpVotes DESC;

