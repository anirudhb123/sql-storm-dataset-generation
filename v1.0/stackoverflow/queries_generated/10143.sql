-- Performance benchmarking query to analyze user activity and post engagement on Stack Overflow

WITH UserPostActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS TotalPosts,
        COUNT(C.Id) AS TotalComments,
        SUM(COALESCE(P.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(P.Score, 0)) AS TotalScore,
        AVG(P.CreationDate - U.CreationDate) AS AvgPostAge,
        SUM(B.Class = 1) AS GoldBadges,
        SUM(B.Class = 2) AS SilverBadges,
        SUM(B.Class = 3) AS BronzeBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
)

SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalViews,
    TotalScore,
    AvgPostAge,
    GoldBadges,
    SilverBadges,
    BronzeBadges
FROM 
    UserPostActivity
ORDER BY 
    TotalScore DESC, TotalPosts DESC
LIMIT 100; -- Adjust limit as per the performance benchmark requirement
