WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM Users U
    LEFT JOIN Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN Votes V ON P.Id = V.PostId
    LEFT JOIN Badges B ON U.Id = B.UserId 
    GROUP BY U.Id, U.DisplayName
),
TopUsers AS (
    SELECT 
        UA.UserId,
        UA.DisplayName,
        UA.PostCount,
        UA.UpvoteCount,
        UA.DownvoteCount,
        ROW_NUMBER() OVER(ORDER BY UA.UpvoteCount DESC) AS Rank
    FROM UserActivity UA
    WHERE UA.PostCount > 0
)
SELECT 
    T.DisplayName,
    T.PostCount,
    T.UpvoteCount,
    T.DownvoteCount,
    (T.UpvoteCount - T.DownvoteCount) AS NetScore,
    T.Rank,
    CASE 
        WHEN B.Class = 1 THEN 'Gold'
        WHEN B.Class = 2 THEN 'Silver'
        WHEN B.Class = 3 THEN 'Bronze'
        ELSE 'No Badge'
    END AS BadgeClass,
    COALESCE(B.Date, 'No Badge Awarded') AS BadgeAwardedDate
FROM TopUsers T
LEFT JOIN Badges B ON T.UserId = B.UserId
WHERE T.Rank <= 10
ORDER BY T.Rank;
