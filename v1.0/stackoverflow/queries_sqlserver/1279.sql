
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
        U.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56')
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
        ROW_NUMBER() OVER (ORDER BY TotalViews DESC, TotalScore DESC) AS Rank
    FROM 
        UserStats
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
    (SELECT STRING_AGG(DISTINCT T.TagName, ', ') 
     FROM Posts P 
     CROSS APPLY STRING_SPLIT(P.Tags, ',') AS T(TagName) 
     WHERE P.OwnerUserId = TU.UserId) AS PopularTags,
    COALESCE(B.BadgeCount, 0) AS BadgeCount
FROM 
    TopUsers TU
LEFT JOIN 
    (SELECT UserId, COUNT(Id) AS BadgeCount 
     FROM Badges 
     GROUP BY UserId) B ON TU.UserId = B.UserId
ORDER BY 
    TU.TotalViews DESC;
