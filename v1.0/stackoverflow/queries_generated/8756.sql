WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        COUNT(DISTINCT B.Id) AS TotalBadges
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStatistics AS (
    SELECT 
        PT.Name AS PostType,
        COUNT(P.Id) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Posts P
    JOIN 
        PostTypes PT ON P.PostTypeId = PT.Id
    GROUP BY 
        PT.Name
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        Rank() OVER (ORDER BY Reputation DESC) AS UserRank
    FROM 
        UserStats
)
SELECT 
    US.DisplayName,
    US.Reputation,
    PS.PostType,
    PS.PostCount,
    PS.AverageScore,
    PS.TotalViews,
    TU.UserRank
FROM 
    UserStats US
JOIN 
    TopUsers TU ON US.UserId = TU.UserId
JOIN 
    PostStatistics PS ON PS.PostCount > 0
ORDER BY 
    TU.UserRank, US.Reputation DESC, PS.PostType;
