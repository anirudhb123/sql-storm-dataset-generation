WITH RecursiveTagHierarchy AS (
    SELECT 
        T.Id AS TagId,
        T.TagName,
        T.Count,
        0 AS Level
    FROM Tags T
    WHERE T.IsModeratorOnly = 0

    UNION ALL

    SELECT 
        T.Id,
        T.TagName,
        T.Count,
        R.Level + 1
    FROM Tags T
    INNER JOIN RecursiveTagHierarchy R ON T.ExcerptPostId = R.TagId 
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.AnswerCount,
        P.ViewCount,
        COALESCE(MAX(V.BountyAmount), 0) AS MaxBountyAmount,
        COUNT(C.CreationDate) AS CommentCount,
        COUNT(DISTINCT B.UserId) AS BadgeCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserRank
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    WHERE P.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY P.Id
),
FilteredPosts AS (
    SELECT 
        PM.PostId,
        PM.Title,
        PM.CreationDate,
        PM.AnswerCount,
        PM.ViewCount,
        PM.MaxBountyAmount,
        PM.CommentCount,
        PM.BadgeCount,
        RANK() OVER (ORDER BY PM.ViewCount DESC) AS RankByViews
    FROM PostMetrics PM
    WHERE PM.BadgeCount > 0
),
PostWithTags AS (
    SELECT 
        FP.*,
        STRING_AGG(RTH.TagName, ', ') AS AssociatedTags
    FROM FilteredPosts FP
    LEFT JOIN Posts P ON FP.PostId = P.Id
    LEFT JOIN RecursiveTagHierarchy RTH ON P.Tags LIKE CONCAT('%', RTH.TagName, '%')
    GROUP BY FP.PostId, FP.Title, FP.CreationDate, FP.AnswerCount, FP.ViewCount, FP.MaxBountyAmount, FP.CommentCount, FP.BadgeCount
)
SELECT 
    PWT.PostId,
    PWT.Title,
    PWT.CreationDate,
    PWT.AnswerCount,
    PWT.ViewCount,
    PWT.MaxBountyAmount,
    PWT.CommentCount,
    PWT.BadgeCount,
    PWT.AssociatedTags,
    CASE 
        WHEN PWT.RankByViews <= 10 THEN 'Top 10 Viewed Posts'
        ELSE 'Other Posts'
    END AS PostClassification
FROM PostWithTags PWT
WHERE PWT.CommentCount > 5
ORDER BY PWT.ViewCount DESC, PWT.CreationDate DESC
LIMIT 100;
