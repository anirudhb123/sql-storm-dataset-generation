WITH RecursivePostCounts AS (
    SELECT 
        Id AS PostId,
        OwnerUserId,
        COUNT(*) AS AnswerCount
    FROM Posts
    WHERE PostTypeId = 2  -- only answers
    GROUP BY Id, OwnerUserId
),
UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS RowNum
    FROM Users U
    WHERE U.Reputation > 0
),
ClosedPostDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        PH.CreationDate AS ClosedDate,
        PH.Comment AS CloseReason
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId = 10  -- Post Closed
),
PostTags AS (
    SELECT
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM Posts P
    JOIN Tags T ON T.ExcerptPostId = P.Id
    WHERE P.PostTypeId = 1  -- only questions
    GROUP BY P.Id
),
AggregatedPostStatistics AS (
    SELECT 
        P.Id,
        P.Title,
        COALESCE(RE.AnswerCount, 0) AS AnswerCount,
        COALESCE(CP.ClosedDate, '') AS ClosedDate,
        COALESCE(CP.CloseReason, 'Not Closed') AS CloseReason,
        COALESCE(PT.Tags, 'No Tags') AS Tags,
        ROW_NUMBER() OVER (ORDER BY P.CreationDate DESC) AS RecentRank
    FROM Posts P
    LEFT JOIN RecursivePostCounts RE ON P.Id = RE.PostId
    LEFT JOIN ClosedPostDetails CP ON P.Id = CP.PostId
    LEFT JOIN PostTags PT ON P.Id = PT.PostId
    WHERE P.PostTypeId = 1  -- only questions
)

SELECT 
    U.DisplayName,
    URe.Reputation,
    APS.Title,
    APS.AnswerCount,
    APS.ClosedDate,
    APS.CloseReason,
    APS.Tags
FROM UserReputation URe
JOIN AggregatedPostStatistics APS ON URe.UserId = APS.OwnerUserId
WHERE URe.RowNum <= 10  -- Top 10 users by reputation
ORDER BY URe.Reputation DESC, APS.RecentRank
LIMIT 50;  -- To limit the number of results for performance benchmarking
