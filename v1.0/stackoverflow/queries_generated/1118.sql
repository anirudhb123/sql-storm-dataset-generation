WITH UserStats AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(SUM(CASE WHEN V.VoteTypeId = 5 THEN 1 ELSE 0 END), 0) AS Favorites
    FROM 
        Users U
    LEFT JOIN 
        Votes V ON U.Id = V.UserId
    GROUP BY 
        U.Id
),
PostAnalytics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.OwnerUserId,
        P.CreationDate,
        P.Score,
        COUNT(C.CreationDate) AS CommentCount,
        COUNT(DISTINCT PL.RelatedPostId) AS RelatedPosts,
        MAX(COALESCE(PH.CreationDate, CURRENT_TIMESTAMP)) AS LastEdit,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS UserPostRank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostLinks PL ON P.Id = PL.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    GROUP BY 
        P.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        Upvotes,
        Downvotes,
        Favorites,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserStats
),
RecentPosts AS (
    SELECT 
        PA.PostId,
        PA.Title,
        PA.OwnerUserId,
        PA.CreationDate,
        PA.Score,
        PA.CommentCount,
        PA.RelatedPosts,
        U.DisplayName AS OwnerDisplayName,
        U.Reputation AS OwnerReputation
    FROM 
        PostAnalytics PA
    JOIN 
        Users U ON PA.OwnerUserId = U.Id
    WHERE 
        PA.CreationDate >= CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    U.UserId,
    U.DisplayName,
    U.Reputation,
    R.PostId,
    R.Title,
    R.CreationDate,
    R.Score,
    R.CommentCount,
    R.RelatedPosts,
    T.ReputationRank
FROM 
    TopUsers T
JOIN 
    RecentPosts R ON T.UserId = R.OwnerUserId
WHERE 
    T.ReputationRank <= 10
ORDER BY 
    T.ReputationRank, R.Score DESC
