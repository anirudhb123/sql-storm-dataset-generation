WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(V.VoteTypeId = 2) AS TotalUpVotes,
        SUM(V.VoteTypeId = 3) AS TotalDownVotes,
        AVG(COALESCE(P.Score, 0)) AS AvgPostScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON U.Id = C.UserId
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    WHERE 
        U.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        U.Id
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.ViewCount,
        P.CreationDate,
        (SELECT COUNT(*) FROM Comments WHERE PostId = P.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 2) AS UpVoteCount,
        (SELECT COUNT(*) FROM Votes WHERE PostId = P.Id AND VoteTypeId = 3) AS DownVoteCount,
        (SELECT COUNT(*) FROM PostHistory WHERE PostId = P.Id) AS EditHistoryCount
    FROM 
        Posts P
    WHERE 
        P.CreationDate >= CURRENT_DATE - INTERVAL '1 year'
)
SELECT 
    UA.DisplayName,
    UA.TotalPosts,
    UA.TotalComments,
    UA.TotalUpVotes,
    UA.TotalDownVotes,
    UA.AvgPostScore,
    PS.Title,
    PS.ViewCount,
    PS.CommentCount,
    PS.UpVoteCount,
    PS.DownVoteCount,
    PS.EditHistoryCount
FROM 
    UserActivity UA
JOIN 
    PostStatistics PS ON UA.UserId = PS.PostId
ORDER BY 
    UA.TotalPosts DESC, UA.TotalUpVotes DESC
LIMIT 50;
