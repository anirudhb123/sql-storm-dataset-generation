-- Performance Benchmarking Query

WITH PostStatistics AS (
    SELECT 
        P.PostTypeId,
        COUNT(*) AS PostCount,
        AVG(P.Score) AS AverageScore,
        SUM(P.ViewCount) AS TotalViews,
        SUM(P.AnswerCount) AS TotalAnswers,
        SUM(P.CommentCount) AS TotalComments,
        SUM(P.FavoriteCount) AS TotalFavorites,
        MAX(P.CreationDate) AS LatestPostDate
    FROM 
        Posts P
    GROUP BY 
        P.PostTypeId
),
UserStatistics AS (
    SELECT 
        U.Id AS UserId,
        COUNT(DISTINCT B.Id) AS TotalBadges,
        SUM(U.UpVotes) AS TotalUpVotes,
        SUM(U.DownVotes) AS TotalDownVotes,
        MAX(U.LastAccessDate) AS LastAccess
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
VoteStatistics AS (
    SELECT 
        V.PostId,
        COUNT(*) AS TotalVotes,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Votes V
    GROUP BY 
        V.PostId
)

SELECT 
    T.Name AS PostType,
    PS.PostCount,
    PS.AverageScore,
    PS.TotalViews,
    PS.TotalAnswers,
    PS.TotalComments,
    PS.TotalFavorites,
    PS.LatestPostDate,
    US.UserId,
    US.TotalBadges,
    US.TotalUpVotes,
    US.TotalDownVotes,
    US.LastAccess,
    VS.TotalVotes,
    VS.UpVotes AS PostUpVotes,
    VS.DownVotes AS PostDownVotes
FROM 
    PostTypes T
LEFT JOIN 
    PostStatistics PS ON T.Id = PS.PostTypeId
LEFT JOIN 
    UserStatistics US ON US.UserId IS NOT NULL
LEFT JOIN 
    VoteStatistics VS ON VS.PostId IS NOT NULL
ORDER BY 
    PS.TotalViews DESC;
