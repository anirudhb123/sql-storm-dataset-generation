
WITH UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        P.AnswerCount,
        P.CommentCount,
        @row_number:=IF(@prev_owner = P.OwnerUserId, @row_number + 1, 1) AS RecentPostRank,
        @prev_owner:=P.OwnerUserId
    FROM 
        Posts P
    JOIN (SELECT @row_number:=0, @prev_owner:=NULL) AS vars
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.Reputation,
    COALESCE(SUM(PS.ViewCount), 0) AS TotalViews,
    COALESCE(COUNT(PS.PostId), 0) AS TotalPosts,
    MAX(PS.Score) AS HighestPostScore
FROM 
    UserActivity UA
LEFT JOIN 
    PostStats PS ON UA.UserId = PS.OwnerUserId AND PS.RecentPostRank <= 5
WHERE 
    UA.Reputation > 100
GROUP BY 
    UA.UserId, UA.DisplayName, UA.Reputation
HAVING 
    COUNT(PS.PostId) > 0 OR MAX(PS.Score) IS NOT NULL
ORDER BY 
    TotalViews DESC, UA.Reputation DESC;
