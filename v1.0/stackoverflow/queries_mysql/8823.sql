
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN P.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalPosts,
        SUM(CASE WHEN C.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalComments,
        SUM(CASE WHEN V.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalVotes,
        SUM(CASE WHEN B.UserId IS NOT NULL THEN 1 ELSE 0 END) AS TotalBadges,
        SUM(P.Score) AS TotalScore,
        COUNT(DISTINCT P.Id) AS UniquePostCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
UserRanked AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalVotes,
        TotalBadges,
        TotalScore,
        RANK() OVER (ORDER BY TotalScore DESC, TotalPosts DESC, TotalComments DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    DisplayName,
    TotalPosts,
    TotalComments,
    TotalVotes,
    TotalBadges,
    TotalScore,
    Rank
FROM 
    UserRanked 
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
