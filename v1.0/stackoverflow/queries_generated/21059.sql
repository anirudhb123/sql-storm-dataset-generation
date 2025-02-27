WITH UserVoteStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(V.Id) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId IN (2, 5) THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        AVG(V.BountyAmount) AS AvgBounty
    FROM Users U
    LEFT JOIN Votes V ON U.Id = V.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM Posts P
    WHERE P.PostTypeId = 1 -- Only questions
),
RecentActivity AS (
    SELECT
        P.Id AS PostId,
        COUNT(CASE WHEN PH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseVotes,
        COUNT(CASE WHEN PH.PostHistoryTypeId = 24 THEN 1 END) AS SuggestedEdits,
        MAX(PH.CreationDate) AS LastActivity
    FROM Posts P
    LEFT JOIN PostHistory PH ON P.Id = PH.PostId
    GROUP BY P.Id
),
CombinedStats AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        Q.PostId,
        Q.Title,
        Q.ViewCount,
        Q.Score,
        R.CloseVotes,
        R.SuggestedEdits,
        R.LastActivity,
        COALESCE(UV.Upvotes, 0) AS UserUpvotes,
        COALESCE(UV.Downvotes, 0) AS UserDownvotes,
        COALESCE(UV.AvgBounty, 0) AS UserAvgBounty
    FROM TopQuestions Q
    JOIN UserVoteStats UV ON Q.PostId = UV.UserId
    JOIN Users U ON Q.PostId = U.Id
    LEFT JOIN RecentActivity R ON Q.PostId = R.PostId
    WHERE Q.PostRank = 1
)
SELECT 
    UserId,
    DisplayName,
    PostId,
    Title,
    ViewCount,
    Score,
    CloseVotes,
    SuggestedEdits,
    LastActivity,
    UserUpvotes,
    UserDownvotes,
    UserAvgBounty
FROM CombinedStats
ORDER BY Score DESC, ViewCount DESC
LIMIT 100;

-- Additionally, some more engaging predicates to see the edge cases
SELECT 
    *,
    CASE 
        WHEN CloseVotes > 5 THEN 'Frequently Closed'
        WHEN SuggestedEdits > 10 THEN 'Highly Edited'
        ELSE 'Average Activity'
    END AS ActivityStatus,
    CASE 
        WHEN UserAvgBounty IS NULL THEN 'No Bounties'
        WHEN UserAvgBounty <= 0 THEN 'Non-Bountying User'
        ELSE 'Engaged in Bounties'
    END AS BountyStatus
FROM CombinedStats
WHERE NULLIF(UserId, -1) IS NOT NULL 
AND UserUpvotes >= 5;
