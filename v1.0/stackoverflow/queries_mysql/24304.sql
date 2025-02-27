
WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) * (B.Class = 1) AS GoldBadges,
        COUNT(B.Id) * (B.Class = 2) AS SilverBadges,
        COUNT(B.Id) * (B.Class = 3) AS BronzeBadges,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBountyAmount
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    LEFT JOIN Votes V ON U.Id = V.UserId AND V.VoteTypeId = 8  
    GROUP BY U.Id, U.DisplayName
),
RecentQuestions AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        @rank := IF(@prev_creation_date = P.CreationDate, @rank, @rank + 1) AS RecentRank,
        @prev_creation_date := P.CreationDate
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    CROSS JOIN (SELECT @rank := 0, @prev_creation_date := NULL) r
    WHERE P.PostTypeId = 1 
    GROUP BY P.Id, P.Title, P.CreationDate, P.Score
),
ActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        @user_rank := @user_rank + 1 AS RecentUserRank,
        U.LastAccessDate,
        U.Reputation
    FROM Users U
    CROSS JOIN (SELECT @user_rank := 0) r
    WHERE U.Reputation > 1000 
    ORDER BY U.LastAccessDate DESC
),
PostClosureDetails AS (
    SELECT 
        PH.PostId,
        MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.CreationDate END) AS ClosedDate,
        COALESCE(NULLIF(MAX(CASE WHEN PH.PostHistoryTypeId = 10 THEN PH.Comment END), ''), 'N/A') AS CloseReason
    FROM PostHistory PH
    GROUP BY PH.PostId
)
SELECT 
    UB.UserId,
    UB.DisplayName,
    Q.Title AS RecentQuestionTitle,
    Q.CreationDate AS QuestionCreationDate,
    Q.Score AS QuestionScore,
    Q.CommentCount AS QuestionCommentCount,
    A.UserId AS ActiveUserId,
    A.DisplayName AS ActiveUserName,
    PCD.ClosedDate,
    PCD.CloseReason,
    (UB.GoldBadges + UB.SilverBadges + UB.BronzeBadges) AS TotalBadges,
    CASE 
        WHEN A.RecentUserRank IS NOT NULL THEN 'Active User'
        ELSE 'Inactive User'
    END AS UserStatus
FROM UserBadgeStats UB
JOIN RecentQuestions Q ON Q.RecentRank <= 10
LEFT JOIN ActiveUsers A ON UB.UserId = A.UserId
LEFT JOIN PostClosureDetails PCD ON Q.PostId = PCD.PostId
WHERE Q.CommentCount > 5 
ORDER BY TotalBadges DESC, Q.Score DESC
LIMIT 50;
