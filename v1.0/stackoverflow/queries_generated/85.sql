WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        U.Views,
        U.UpVotes,
        U.DownVotes,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS RecentPostRank
    FROM Posts P
    JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate > NOW() - INTERVAL '30 days'
),
PostComments AS (
    SELECT 
        C.PostId,
        COUNT(*) AS CommentCount,
        AVG(C.Score) AS AvgCommentScore
    FROM Comments C
    GROUP BY C.PostId
),
TopUsers AS (
    SELECT 
        UR.UserId,
        UR.DisplayName,
        UR.Reputation,
        COALESCE(PC.CommentCount, 0) AS CommentCount,
        RANK() OVER (ORDER BY UR.Reputation + COALESCE(PC.CommentCount, 0) DESC) AS UserScoreRank
    FROM UserReputation UR
    LEFT JOIN PostComments PC ON UR.UserId = PC.PostId
    WHERE UR.Reputation > 1000
)
SELECT 
    TU.DisplayName,
    TU.Reputation,
    TU.CommentCount,
    RP.Title AS RecentPostTitle,
    RP.CreationDate AS RecentPostDate,
    RP.ViewCount AS RecentPostViewCount,
    RP.Score AS RecentPostScore,
    PH.UserDisplayName AS PostLastEditor,
    PH.Comment AS EditComment
FROM TopUsers TU
LEFT JOIN RecentPosts RP ON TU.UserId = RP.OwnerDisplayName
LEFT JOIN PostHistory PH ON RP.PostId = PH.PostId AND PH.PostHistoryTypeId IN (4, 5) -- 4 = Edit Title, 5 = Edit Body
WHERE TU.UserScoreRank <= 10
  AND (RP.RecentPostRank = 1 OR RP.RecentPostRank IS NULL)
ORDER BY TU.Reputation DESC, RP.ViewCount DESC;
