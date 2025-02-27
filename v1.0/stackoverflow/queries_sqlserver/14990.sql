
WITH UserPostCounts AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        COUNT(P.Id) AS PostCount
    FROM 
        Users AS U
    LEFT JOIN 
        Posts AS P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.Reputation
),

UserBadgeCounts AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges AS B
    GROUP BY 
        B.UserId
),

OverallStats AS (
    SELECT
        UPC.UserId,
        UPC.Reputation,
        UPC.PostCount,
        COALESCE(UBC.BadgeCount, 0) AS BadgeCount
    FROM 
        UserPostCounts AS UPC
    LEFT JOIN 
        UserBadgeCounts AS UBC ON UPC.UserId = UBC.UserId
)

SELECT 
    UserId,
    Reputation,
    PostCount,
    BadgeCount,
    (PostCount + BadgeCount) AS TotalScore
FROM 
    OverallStats
ORDER BY 
    TotalScore DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
