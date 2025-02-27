WITH UserBadgeStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users U
    LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY U.Id, U.DisplayName
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS RankScore
    FROM Posts P
    INNER JOIN Users U ON P.OwnerUserId = U.Id
    WHERE P.CreationDate >= NOW() - INTERVAL '30 days'
),
PostsWithComments AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        COALESCE(COUNT(C.Id), 0) AS CommentCount
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    WHERE P.PostTypeId IN (1, 2) -- Only Questions and Answers
    GROUP BY P.Id, P.Title
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        MIN(PH.CreationDate) AS FirstClosedDate,
        COUNT(*) AS TotalCloseVotes
    FROM PostHistory PH
    WHERE PH.PostHistoryTypeId = 10 -- Closed status
    GROUP BY PH.PostId
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation,
    U.BadgeCount,
    T.Title AS TopPostTitle,
    T.Score AS TopPostScore,
    T.ViewCount AS TopPostViews,
    PC.CommentCount,
    CP.TotalCloseVotes,
    CASE 
        WHEN CP.PostId IS NOT NULL THEN 'Closed' 
        ELSE 'Open' 
    END AS PostStatus
FROM UserBadgeStats U
JOIN TopPosts T ON U.UserId = T.OwnerId
LEFT JOIN PostsWithComments PC ON T.PostId = PC.PostId
LEFT JOIN ClosedPosts CP ON T.PostId = CP.PostId
WHERE U.Reputation > 1000
AND U.BadgeCount > 0
AND (PC.CommentCount > 5 OR T.Score > 50)
ORDER BY U.Reputation DESC, T.Score DESC;
