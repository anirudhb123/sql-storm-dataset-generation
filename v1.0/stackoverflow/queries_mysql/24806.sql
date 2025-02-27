
WITH UserReputation AS (
    SELECT 
        Id AS UserId,
        Reputation,
        CASE 
            WHEN Reputation IS NULL THEN 'Unknown'
            WHEN Reputation <= 100 THEN 'Low Reputation'
            WHEN Reputation BETWEEN 101 AND 1000 THEN 'Medium Reputation'
            ELSE 'High Reputation'
        END AS ReputationCategory
    FROM Users
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.PostTypeId,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPostCount
    FROM Posts P
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Badges B ON P.OwnerUserId = B.UserId
    LEFT JOIN PostLinks PL ON P.Id = PL.PostId
    GROUP BY P.Id, P.PostTypeId
),
FilteredPosts AS (
    SELECT 
        PS.PostId,
        PS.PostTypeId,
        PS.UpVotes,
        PS.DownVotes,
        PS.CommentCount,
        PS.BadgeCount,
        PS.RelatedPostCount,
        U.ReputationCategory
    FROM PostStatistics PS
    LEFT JOIN UserReputation U ON PS.PostId = U.UserId  
    WHERE PS.UpVotes - PS.DownVotes > 0
)
SELECT 
    FP.PostId,
    FP.PostTypeId,
    FP.UpVotes,
    FP.DownVotes,
    FP.CommentCount,
    FP.BadgeCount,
    FP.RelatedPostCount,
    FP.ReputationCategory,
    CASE 
        WHEN FP.ReputationCategory = 'Unknown' THEN 'No Users with Votes'
        WHEN FP.UpVotes = 0 AND FP.DownVotes = 0 THEN 'No Votes'
        ELSE 'Active Discussion'
    END AS DiscussionStatus,
    @row_number := IF(@prev_ReputationCategory = FP.ReputationCategory, @row_number + 1, 1) AS UserRank,
    @prev_ReputationCategory := FP.ReputationCategory
FROM FilteredPosts FP, (SELECT @row_number := 0, @prev_ReputationCategory := '') AS vars
WHERE FP.CommentCount > 5 OR (FP.BadgeCount > 0 AND FP.RelatedPostCount > 10)
ORDER BY FP.ReputationCategory, FP.UpVotes DESC
LIMIT 50 OFFSET 0;
