WITH RecursiveTagCTE AS (
    SELECT 
        Id,
        TagName,
        Count,
        ExcerptPostId,
        1 AS Depth
    FROM Tags
    WHERE IsModeratorOnly = 0  -- Exclude moderator-only tags

    UNION ALL

    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        T.ExcerptPostId,
        RTC.Depth + 1
    FROM Tags T
    INNER JOIN RecursiveTagCTE RTC ON T.WikiPostId = RTC.Id
    WHERE T.IsRequired = 0  -- Further explore required tags
),
PostsWithTagStats AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpvoteCount,  -- Count of upvotes
        SUM(COALESCE(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END, 0)) AS DownvoteCount,  -- Count of downvotes
        STRING_AGG(DISTINCT T.TagName, ', ') AS TagsList  -- Aggregate tag names
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Tags T ON T.ExcerptPostId = P.Id
    GROUP BY P.Id
),
CloseReasons AS (
    SELECT 
        PH.PostId,
        PH.Comment AS CloseReason,
        PH.CreationDate
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10  -- Post Closed
),
FinalPostStats AS (
    SELECT 
        PWT.PostId,
        PWT.Title,
        PWT.CreationDate,
        PWT.ViewCount,
        PWT.UpvoteCount,
        PWT.DownvoteCount,
        PWT.TagsList,
        COALESCE(CR.CloseReason, 'Not Closed') AS CloseReason
    FROM PostsWithTagStats PWT
    LEFT JOIN CloseReasons CR ON PWT.PostId = CR.PostId
)
SELECT 
    FPS.PostId,
    FPS.Title,
    FPS.CreationDate,
    FPS.ViewCount,
    FPS.UpvoteCount,
    FPS.DownvoteCount,
    FPS.TagsList,
    FPS.CloseReason,
    RANK() OVER (ORDER BY FPS.UpvoteCount DESC) AS Rank,  -- Ranking based on upvotes 
    ROW_NUMBER() OVER (PARTITION BY COALESCE(FPS.CloseReason, 'Not Closed') ORDER BY FPS.CreationDate DESC) AS CloseReasonOrder  -- Sequential order by Close Reason
FROM FinalPostStats FPS
WHERE FPS.ViewCount > 100  -- Filter posts with significant views
ORDER BY FPS.UpvoteCount DESC, FPS.ViewCount DESC;  -- Order by upvotes and then views
