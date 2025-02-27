
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
RecentActivity AS (
    SELECT 
        U.Id AS UserId,
        MAX(P.CreationDate) AS LastPostDate,
        MAX(C.CreationDate) AS LastCommentDate
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    GROUP BY 
        U.Id
),
CombinedStats AS (
    SELECT 
        Us.UserId,
        Us.DisplayName,
        Us.Reputation,
        Us.TotalPosts,
        Us.TotalComments,
        Us.TotalUpVotes,
        Us.TotalDownVotes,
        Ra.LastPostDate,
        Ra.LastCommentDate,
        @rank := IF(@prev_reputation = Us.Reputation, @rank, @rank + 1) AS ReputationRank,
        @prev_reputation := Us.Reputation
    FROM 
        UserStats Us
    JOIN 
        RecentActivity Ra ON Us.UserId = Ra.UserId,
        (SELECT @rank := 0, @prev_reputation := NULL) r
    ORDER BY 
        Us.Reputation DESC
)
SELECT 
    C.UserId,
    C.DisplayName,
    C.Reputation,
    C.TotalPosts,
    C.TotalComments,
    C.TotalUpVotes,
    C.TotalDownVotes,
    C.LastPostDate,
    C.LastCommentDate,
    C.ReputationRank
FROM 
    CombinedStats C
WHERE 
    C.TotalPosts > 10 AND 
    C.Reputation > 1000
ORDER BY 
    C.ReputationRank;
