WITH UserReputation AS (
    SELECT 
        Id AS UserId, 
        Reputation, 
        ROW_NUMBER() OVER (ORDER BY Reputation DESC) AS Rank
    FROM 
        Users
),
PostStats AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 2 THEN 1 END), 0) AS Upvotes,
        COALESCE(COUNT(CASE WHEN V.VoteTypeId = 3 THEN 1 END), 0) AS Downvotes,
        COALESCE(COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END), 0) AS CommentCount,
        COALESCE(P.ViewCount, 0) AS ViewCount,
        P.OwnerUserId
    FROM
        Posts P
    LEFT JOIN 
        Votes V ON P.Id = V.PostId 
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= current_date - interval '30 days'
    GROUP BY 
        P.Id
),
PostWithComments AS (
    SELECT 
        PS.PostId,
        PS.Title,
        PS.CreationDate,
        PS.Upvotes,
        PS.Downvotes,
        PS.CommentCount, 
        PS.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        U.Location AS OwnerLocation,
        RANK() OVER (ORDER BY PS.Upvotes - PS.Downvotes DESC) AS PostRank
    FROM 
        PostStats PS
    JOIN 
        Users U ON PS.OwnerUserId = U.Id
),
TopPosts AS (
    SELECT 
        PWC.*, 
        UR.Reputation AS OwnerReputation
    FROM 
        PostWithComments PWC
    JOIN 
        UserReputation UR ON PWC.OwnerUserId = UR.UserId
    WHERE 
        PWC.PostRank <= 10
)
SELECT 
    T.Title,
    T.ViewCount,
    T.CommentCount,
    T.Upvotes,
    T.Downvotes,
    T.OwnerDisplayName,
    T.OwnerReputation,
    CASE 
        WHEN T.OwnerReputation IS NULL THEN 'Unknown'
        WHEN T.OwnerReputation > 1000 THEN 'High Reputation'
        WHEN T.OwnerReputation BETWEEN 500 AND 1000 THEN 'Medium Reputation'
        ELSE 'Low Reputation'
    END AS ReputationCategory,
    CASE 
        WHEN EXISTS (SELECT 1 FROM Posts P WHERE P.AcceptedAnswerId = T.PostId) 
        THEN 'Has Accepted Answer' 
        ELSE 'No Accepted Answer' 
    END AS AnswerStatus
FROM 
    TopPosts T
ORDER BY 
    T.PostRank;
