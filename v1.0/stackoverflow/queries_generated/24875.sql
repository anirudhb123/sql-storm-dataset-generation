WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS TotalAcceptedAnswers,
        AVG(V.BountyAmount) AS AverageBounty
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId AND V.VoteTypeId = 8 -- BountyStart
    GROUP BY U.Id
),
PostHistoryData AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.Score,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        PH.UserId AS EditorId,
        PH.Comment,
        ROW_NUMBER() OVER (PARTITION BY P.Id ORDER BY PH.CreationDate DESC) AS EditRank
    FROM Posts P
    JOIN PostHistory PH ON P.Id = PH.PostId
    WHERE PH.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Edit Body, Edit Tags
),
RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id
),
FinalPostMetrics AS (
    SELECT
        PHD.PostId,
        PHD.Title,
        PHD.ViewCount,
        PHD.Score,
        COALESCE(PHM.TotalPosts, 0) AS UserTotalPosts,
        COALESCE(UM.Reputation, 0) AS UserReputation,
        COALESCE(UP.UpVotes, 0) AS UpVotesCount,
        COALESCE(DOWN.DownVotes, 0) AS DownVotesCount
    FROM PostHistoryData PHD
    LEFT JOIN UserMetrics UM ON PHD.EditorId = UM.UserId
    LEFT JOIN RankedPosts UP ON PHD.PostId = UP.PostId
    LEFT JOIN RankedPosts DOWN ON PHD.PostId = DOWN.PostId
    WHERE PHD.EditRank = 1 
    AND PHD.PostHistoryTypeId = 4 -- Latest edit type is Title Edit
)
SELECT 
    FPM.PostId,
    FPM.Title,
    FPM.ViewCount,
    FPM.Score,
    FPM.UserTotalPosts,
    FPM.UserReputation,
    CASE WHEN FPM.UserReputation IS NULL THEN 'User not found' ELSE 'User exists' END AS UserStatus,
    (CASE 
        WHEN FPM.UpVotesCount - FPM.DownVotesCount > 0 THEN 'Positive Feedback'
        ELSE 'Neutral or Negative Feedback' 
    END) AS FeedbackAssessment
FROM FinalPostMetrics FPM
WHERE FPM.ViewCount > 100
ORDER BY FPM.Score DESC, FPM.Title;

