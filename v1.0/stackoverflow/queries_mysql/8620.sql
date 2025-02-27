
WITH UserStatistics AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        U.Reputation, 
        COALESCE(SUM(P.ViewCount), 0) AS TotalViewCount,
        COALESCE(SUM(P.Score), 0) AS TotalScore,
        COUNT(DISTINCT P.Id) AS PostCount,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        Reputation, 
        TotalViewCount, 
        TotalScore, 
        PostCount, 
        CommentCount, 
        BadgeCount,
        @row_number := @row_number + 1 AS UserRank
    FROM 
        UserStatistics, (SELECT @row_number := 0) AS rn
    ORDER BY 
        Reputation DESC, TotalScore DESC
)
SELECT 
    UserId, 
    DisplayName, 
    Reputation, 
    TotalViewCount, 
    TotalScore, 
    PostCount, 
    CommentCount, 
    BadgeCount,
    UserRank
FROM 
    RankedUsers
WHERE 
    UserRank <= 10
ORDER BY 
    UserRank;
