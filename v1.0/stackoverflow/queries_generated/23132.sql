WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS QuestionCount,
        SUM(V.BountyAmount) AS TotalBountyAmount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpvoteCount,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownvoteCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId AND P.PostTypeId = 1
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(P.ViewCount) AS TotalViews,
        AVG(P.Score) AS AvgScore
    FROM Tags T
    LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%', T.TagName, '%')
    GROUP BY T.TagName
    HAVING COUNT(P.Id) > 10
),
PostMetrics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(C.Id) AS CommentCount,
        MAX(V.CreationDate) AS LastVoteDate,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.OwnerUserId
),
RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY PH.PostId ORDER BY PH.CreationDate DESC) AS RecentEventRank
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId IN (10, 12, 17)
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    UA.QuestionCount,
    UA.TotalBountyAmount,
    UA.UpvoteCount,
    UA.DownvoteCount,
    PT.TagName,
    PT.PostCount,
    PT.TotalViews,
    PT.AvgScore,
    PM.PostId,
    PM.Title,
    PM.CommentCount,
    PM.LastVoteDate,
    PM.PostRank,
    COALESCE(PHPHG.PostHistoryTypeId, 'No Recent Closure') AS RecentPostHistoryType,
    COALESCE(PHPHG.CreationDate, CURRENT_TIMESTAMP) AS LastEventDate
FROM UserActivity UA
LEFT JOIN PopularTags PT ON UA.QuestionCount > 5
LEFT JOIN PostMetrics PM ON UA.UserId = PM.OwnerUserId
LEFT JOIN RecentPostHistory PHPHG ON PM.PostId = PHPHG.PostId AND PHPHG.RecentEventRank = 1
WHERE 
    UA.Reputation > (SELECT AVG(Reputation) FROM Users)
    AND (PT.TotalViews IS NULL OR PT.TotalViews > 100)
ORDER BY UA.Reputation DESC, PT.PostCount DESC, PM.PostRank ASC;
