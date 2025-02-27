WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViewCount,
        SUM(COALESCE(C.Score, 0)) AS TotalCommentScore
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Comments C ON U.Id = C.UserId
    GROUP BY U.Id, U.DisplayName, U.Reputation
),
TopBadges AS (
    SELECT 
        B.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(B.Name, ', ') AS BadgeNames
    FROM Badges B
    GROUP BY B.UserId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        COALESCE(P.AcceptedAnswerId, -1) AS AcceptedAnswerId,
        COUNT(DISTINCT C.Id) AS CommentCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS Upvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS Downvotes,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.ViewCount DESC) AS UserPostRank
    FROM Posts P
    LEFT JOIN Comments C ON P.Id = C.PostId
    LEFT JOIN Votes V ON P.Id = V.PostId
    GROUP BY P.Id, P.Title, P.Score, P.ViewCount, P.CreationDate, P.AcceptedAnswerId
),
ClosedPostStats AS (
    SELECT 
        PH.PostId,
        PH.PostHistoryTypeId,
        PH.CreationDate,
        STRING_AGG(DISTINCT CR.Name, ', ') AS ClosedReasons
    FROM PostHistory PH
    JOIN CloseReasonTypes CR ON PH.Comment::int = CR.Id
    WHERE PH.PostHistoryTypeId IN (10, 11) -- Closed or Reopened
    GROUP BY PH.PostId, PH.PostHistoryTypeId, PH.CreationDate
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    COALESCE(TB.BadgeCount, 0) AS BadgeCount,
    COALESCE(TB.BadgeNames, 'None') AS BadgeNames,
    U.TotalViewCount,
    U.TotalCommentScore,
    P.PostId,
    P.Title,
    P.Score,
    P.ViewCount,
    P.CommentCount,
    P.Upvotes,
    P.Downvotes,
    P.UserPostRank,
    COALESCE(CPS.ClosedReasons, 'No reasons') AS ClosedReasons
FROM UserReputation U
LEFT JOIN TopBadges TB ON U.UserId = TB.UserId
LEFT JOIN PostStatistics P ON U.UserId = P.OwnerUserId
LEFT JOIN ClosedPostStats CPS ON P.PostId = CPS.PostId
WHERE U.Reputation > 100 -- Filter users with reputation > 100
   AND (P.ViewCount > 100 OR P.CommentCount > 10 OR U.TotalCommentScore > 50)
ORDER BY U.Reputation DESC, P.ViewCount DESC;
