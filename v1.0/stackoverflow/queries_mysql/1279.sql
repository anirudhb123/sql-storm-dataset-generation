
WITH UserStats AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COALESCE(SUM(P.ViewCount), 0) AS TotalViews, 
        COALESCE(SUM(P.Score), 0) AS TotalScore, 
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    WHERE 
        U.CreationDate >= (NOW() - INTERVAL 1 YEAR)
    GROUP BY 
        U.Id, U.DisplayName
), 
RankedUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalViews, 
        TotalScore, 
        TotalPosts, 
        TotalComments,
        @rank := @rank + 1 AS Rank
    FROM 
        UserStats, 
        (SELECT @rank := 0) r
    ORDER BY 
        TotalViews DESC, TotalScore DESC
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalViews, 
        TotalScore, 
        TotalPosts, 
        TotalComments
    FROM 
        RankedUsers 
    WHERE 
        Rank <= 10
)
SELECT 
    TU.*, 
    (SELECT GROUP_CONCAT(DISTINCT T.TagName SEPARATOR ', ') 
     FROM Posts P 
     JOIN (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, ',', numbers.n), ',', -1)) AS TagName
           FROM Posts P
           JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 
                 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 
                 UNION ALL SELECT 9 UNION ALL SELECT 10) numbers 
           ON CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, ',', '')) >= numbers.n - 1) AS T 
     ON P.OwnerUserId = TU.UserId) AS PopularTags,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers TU
LEFT JOIN 
    (SELECT UserId, COUNT(Id) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) B ON TU.UserId = B.UserId
ORDER BY 
    TU.TotalViews DESC;
