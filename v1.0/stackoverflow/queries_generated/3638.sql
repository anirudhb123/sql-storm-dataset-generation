WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (ORDER BY U.Reputation DESC) AS ReputationRank
    FROM Users U
),
PopularPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COUNT(CM.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM Posts P
    LEFT JOIN Comments CM ON P.Id = CM.PostId
    WHERE P.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS ClosedDate,
        DATEDIFF(MINUTE, PH.CreationDate, CURRENT_TIMESTAMP) AS MinutesClosed,
        R.Name AS Reason
    FROM PostHistory PH
    JOIN CloseReasonTypes R ON PH.Comment::int = R.Id
    WHERE PH.PostHistoryTypeId = 10
)
SELECT 
    UR.DisplayName AS UserName,
    UR.Reputation AS UserReputation,
    COALESCE(PP.Title, 'No Posts') AS PostTitle,
    COALESCE(PP.Score, 0) AS PostScore,
    COALESCE(PP.ViewCount, 0) AS PostViewCount,
    COALESCE(PP.CommentCount, 0) AS PostCommentCount,
    CP.ClosedDate,
    CP.MinutesClosed,
    CP.Reason
FROM UserReputation UR
LEFT JOIN PopularPosts PP ON UR.UserId = PP.OwnerUserId AND PP.PostRank = 1
LEFT JOIN ClosedPosts CP ON PP.PostId = CP.PostId
WHERE UR.Reputation > (SELECT AVG(Reputation) FROM Users) 
  AND (PP.Score IS NOT NULL OR CP.PostId IS NOT NULL)
ORDER BY UR.Reputation DESC, CP.MinutesClosed DESC;
