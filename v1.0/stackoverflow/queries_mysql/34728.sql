
WITH MostActiveUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(IFNULL(P.ViewCount, 0)) AS TotalViews,
        SUM(IFNULL(P.Score, 0)) AS TotalScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeList
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
UserScores AS (
    SELECT 
        U.UserId,
        U.DisplayName,
        U.PostCount,
        U.TotalViews,
        U.TotalScore,
        IFNULL(UB.BadgeCount, 0) AS BadgeCount,
        IFNULL(UB.BadgeList, 'No Badges') AS BadgeList
    FROM 
        MostActiveUsers U
    LEFT JOIN 
        UserBadges UB ON U.UserId = UB.UserId
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        P.Score,
        P.OwnerUserId,
        @rank := IF(@prevOwnerUserId = P.OwnerUserId, @rank + 1, 1) AS PostRank,
        @prevOwnerUserId := P.OwnerUserId
    FROM 
        Posts P,
        (SELECT @rank := 0, @prevOwnerUserId := NULL) r
    WHERE 
        P.PostTypeId = 1  
    ORDER BY 
        P.OwnerUserId, P.Score DESC
)
SELECT 
    U.DisplayName,
    U.PostCount,
    U.TotalViews,
    U.TotalScore,
    U.BadgeCount,
    U.BadgeList,
    TP.Title AS TopPostTitle,
    TP.ViewCount AS TopPostViews,
    TP.Score AS TopPostScore,
    TP.CreationDate AS TopPostDate
FROM 
    UserScores U
LEFT JOIN 
    TopPosts TP ON U.UserId = TP.OwnerUserId AND TP.PostRank = 1
ORDER BY 
    U.TotalScore DESC,
    U.PostCount DESC
LIMIT 10;
