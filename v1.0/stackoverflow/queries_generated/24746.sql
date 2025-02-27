WITH UserReputation AS (
    SELECT 
        U.Id AS UserId, 
        U.Reputation, 
        U.DisplayName, 
        U.CreationDate,
        RANK() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PostDetails AS (
    SELECT 
        P.Id AS PostId, 
        P.OwnerUserId, 
        P.PostTypeId, 
        P.Title, 
        P.CreationDate,
        COALESCE((SELECT AVG(VoteTypeId) FROM Votes V WHERE V.PostId = P.Id AND V.VoteTypeId = 2), 0) AS UpvoteCount,
        (SELECT COUNT(*) FROM Comments C WHERE C.PostId = P.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS LatestPost
    FROM Posts P
    WHERE P.OwnerUserId IS NOT NULL
),
ClosedPostDetails AS (
    SELECT 
        PH.PostId, 
        PH.CreationDate,
        CT.Name AS CloseReason
    FROM PostHistory PH
    JOIN CloseReasonTypes CT ON CT.Id = CAST(PH.Comment AS int)
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened posts
),
UserBadges AS (
    SELECT 
        B.UserId, 
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges B
    GROUP BY B.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    P.Title,
    P.UpvoteCount,
    P.CommentCount,
    COALESCE(Closed.CloseReason, 'Not Closed') AS CloseReason,
    COALESCE(UB.GoldBadges, 0) AS GoldBadges,
    COALESCE(UB.SilverBadges, 0) AS SilverBadges,
    COALESCE(UB.BronzeBadges, 0) AS BronzeBadges,
    (CASE 
        WHEN UReputation.ReputationRank <= 10 THEN 'Top User'
        WHEN UReputation.ReputationRank BETWEEN 11 AND 50 THEN 'Moderate User'
        ELSE 'New User'
    END) AS UserTier
FROM UserReputation UReputation
JOIN PostDetails P ON UReputation.UserId = P.OwnerUserId
LEFT JOIN ClosedPostDetails Closed ON P.PostId = Closed.PostId
LEFT JOIN UserBadges UB ON UReputation.UserId = UB.UserId
WHERE P.LatestPost = 1
ORDER BY UReputation.Reputation DESC, P.UpvoteCount DESC
FETCH FIRST 100 ROWS ONLY;
