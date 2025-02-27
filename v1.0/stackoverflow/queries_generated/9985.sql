WITH RankedUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        ROW_NUMBER() OVER (PARTITION BY U.Location ORDER BY U.Reputation DESC) AS ReputationRank
    FROM 
        Users U
    WHERE 
        U.Reputation > 1000
),
ActivePosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(C.Id) AS CommentCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        PostHistory PH ON P.Id = PH.PostId
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score
),
TopPosts AS (
    SELECT 
        AP.PostId,
        AP.Title,
        AP.CreationDate,
        AP.Score,
        AP.CommentCount,
        RANK() OVER (ORDER BY AP.Score DESC, AP.CommentCount DESC) AS PostRank
    FROM 
        ActivePosts AP
)
SELECT 
    U.DisplayName AS UserName,
    U.Reputation AS UserReputation,
    TP.Title AS PostTitle,
    TP.Score AS PostScore,
    TP.CommentCount AS PostCommentCount
FROM 
    RankedUsers U
JOIN 
    Posts P ON U.UserId = P.OwnerUserId
JOIN 
    TopPosts TP ON P.Id = TP.PostId
WHERE 
    U.ReputationRank <= 5 AND TP.PostRank <= 10
ORDER BY 
    U.Location, U.Reputation DESC, TP.Score DESC;
