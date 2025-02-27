WITH UserBadgeCounts AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
RecentPosts AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank
    FROM 
        Posts P
    WHERE 
        P.Score > 0 AND
        P.CreationDate >= NOW() - INTERVAL '30 days'
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        PH.CreationDate,
        PH.Comment AS CloseReason 
    FROM 
        PostHistory PH 
    WHERE 
        PH.PostHistoryTypeId = 10 
)
SELECT 
    U.DisplayName,
    U.Reputation,
    U.GoldBadges,
    U.SilverBadges,
    U.BronzeBadges,
    R.Title AS RecentPostTitle,
    R.Score AS RecentPostScore,
    COALESCE(CP.CloseReason, 'Not Closed') AS PostCloseReason,
    CASE 
        WHEN U.Location IS NULL THEN 'No Location Provided' 
        ELSE U.Location 
    END AS UserLocation
FROM 
    UserBadgeCounts U 
LEFT JOIN 
    RecentPosts R ON U.UserId = R.OwnerUserId AND R.PostRank = 1
LEFT JOIN 
    ClosedPosts CP ON R.PostId = CP.PostId
WHERE 
    (U.GoldBadges > 3 OR U.SilverBadges > 5 OR U.BronzeBadges > 10)
    AND (U.Reputation > 500 OR U.CreatedAt <= NOW() - INTERVAL '5 years')
ORDER BY 
    U.Reputation DESC, R.Score DESC NULLS LAST
LIMIT 50;

This SQL query leverages multiple advanced SQL concepts including:

1. Common Table Expressions (CTEs) to organize and encapsulate complex logic.
2. Window functions for ranking and partitioning the data based on post creation dates per user.
3. Outer joins to gather related data across different tables while accommodating users without any recent posts or badges.
4. Conditional aggregation using CASE statements to count badge types.
5. NULL logic to handle cases where users may not have a specified location or posts that might not be closed, providing default messages.
6. Complex predicates with logical OR and AND conditions to filter users based on their badge count and reputation.
7. The use of COALESCE to manage potential NULL values in the close reason.

This intricate structure allows for insightful benchmarking and performance testing of SQL capabilities.
