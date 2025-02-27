WITH UserMetrics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments,
        SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END) AS TotalUpvotes,
        SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END) AS TotalDownvotes
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
HighReputationUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        TotalUpvotes,
        TotalDownvotes
    FROM 
        UserMetrics
    WHERE 
        Reputation > 1000
),
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS PostRank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
)
SELECT 
    H.UserId,
    H.DisplayName,
    H.Reputation,
    H.TotalPosts,
    H.TotalComments,
    H.TotalUpvotes,
    H.TotalDownvotes,
    TP.PostId,
    TP.Title,
    TP.Score,
    TP.CreationDate
FROM 
    HighReputationUsers H
LEFT JOIN 
    TopPosts TP ON H.UserId = TP.OwnerUserId AND TP.PostRank <= 3
ORDER BY 
    H.Reputation DESC, 
    TP.Score DESC;
