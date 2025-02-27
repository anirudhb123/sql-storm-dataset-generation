
WITH UserVoteSummary AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        AVG(U.Reputation) AS AvgReputation
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    LEFT JOIN 
        Posts P ON V.PostId = P.Id
    WHERE 
        U.Reputation > 100
    GROUP BY 
        U.Id, U.DisplayName
),
PostScoreRanked AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        @rank := IF(@prev_score = P.Score, @rank, @row_number) AS ScoreRank,
        @row_number := @row_number + 1 AS row_num,
        COALESCE(C.CountId, 0) AS TotalComments
    FROM 
        Posts P
    LEFT JOIN 
        (SELECT PostId, COUNT(Id) AS CountId 
         FROM Comments
         GROUP BY PostId) C ON P.Id = C.PostId,
        (SELECT @rank := 0, @row_number := 1, @prev_score := NULL) AS vars
    WHERE 
        P.CreationDate >= NOW() - INTERVAL 1 YEAR
    ORDER BY 
        P.Score DESC
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount,
        GROUP_CONCAT(CT.Name ORDER BY CT.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory PH
    JOIN 
        CloseReasonTypes CT ON PH.Comment = CT.Id
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    U.DisplayName,
    U.TotalUpVotes,
    U.TotalDownVotes,
    U.TotalPosts,
    U.AvgReputation,
    PS.PostId,
    PS.Title,
    PS.Score,
    PS.ScoreRank,
    PS.TotalComments,
    COALESCE(CP.CloseCount, 0) AS CloseCount,
    COALESCE(CP.CloseReasons, 'None') AS CloseReasons
FROM 
    UserVoteSummary U
JOIN 
    PostScoreRanked PS ON U.TotalPosts > 5
LEFT JOIN 
    ClosedPosts CP ON PS.PostId = CP.PostId
ORDER BY 
    U.TotalUpVotes DESC, PS.Score DESC
LIMIT 50;
