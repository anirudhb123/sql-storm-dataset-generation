
WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
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
        Votes V ON P.Id = V.PostId AND V.UserId = U.Id
    GROUP BY 
        U.Id, U.Reputation
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpVotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownVotes,
        AVG(P.Score) AS AvgScore,
        COUNT(DISTINCT PH.Id) AS TotalHistoryChanges
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        @userRank := @userRank + 1 AS ReputationRank
    FROM 
        UserStats, (SELECT @userRank := 0) r
    ORDER BY 
        Reputation DESC
),
TopPosts AS (
    SELECT 
        PostId,
        OwnerUserId,
        PostTypeId,
        TotalComments,
        TotalUpVotes,
        TotalDownVotes,
        AvgScore,
        TotalHistoryChanges,
        @postRank := @postRank + 1 AS AvgScoreRank
    FROM 
        PostStatistics, (SELECT @postRank := 0) r
    ORDER BY 
        AvgScore DESC
)

SELECT 
    U.UserId,
    U.Reputation,
    U.TotalPosts,
    U.TotalComments,
    U.TotalUpVotes,
    U.TotalDownVotes,
    P.PostId,
    P.PostTypeId,
    P.TotalComments AS PostComments,
    P.TotalUpVotes AS PostUpVotes,
    P.TotalDownVotes AS PostDownVotes,
    P.AvgScore,
    P.TotalHistoryChanges,
    U.ReputationRank,
    P.AvgScoreRank
FROM 
    TopUsers U
JOIN 
    TopPosts P ON U.UserId = P.OwnerUserId
ORDER BY 
    U.Reputation DESC, P.AvgScore DESC
LIMIT 10;
