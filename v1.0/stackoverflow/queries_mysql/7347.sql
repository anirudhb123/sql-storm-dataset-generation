
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(TIMESTAMPDIFF(SECOND, P.CreationDate, P.LastActivityDate) / 3600) AS AvgPostAgeHours
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        PH.PostHistoryTypeId,
        PH.CreationDate AS HistoryDate,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE
        PH.CreationDate > NOW() - INTERVAL 1 YEAR
)
SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    UA.AvgPostAgeHours,
    PS.PostId,
    PS.Title,
    PS.ViewCount,
    PS.Score,
    PS.HistoryDate
FROM 
    UserActivity UA
JOIN 
    PostStatistics PS ON UA.UserId = PS.OwnerUserId
ORDER BY 
    UA.TotalPosts DESC, PS.ViewCount DESC
LIMIT 100;
