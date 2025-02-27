WITH RankedPosts AS (
    SELECT 
        P.Id AS PostID,
        P.Title,
        P.Score,
        P.ViewCount,
        P.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS rn
    FROM 
        Posts P
    WHERE 
        P.PostTypeId = 1 AND 
        P.Score > 0 AND 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
UserPostStats AS (
    SELECT 
        U.Id AS UserID,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(P.Score) AS TotalScore,
        SUM(P.ViewCount) AS TotalViews
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
),
TopPosts AS (
    SELECT 
        RP.PostID,
        RP.Title,
        RP.Score,
        RP.ViewCount,
        UP.UserID,
        UP.DisplayName,
        UP.Reputation
    FROM 
        RankedPosts RP
    JOIN 
        UserPostStats UP ON RP.PostID = UP.UserID
    WHERE 
        RP.rn <= 5
)
SELECT 
    T.Title,
    T.Score,
    T.ViewCount,
    U.DisplayName AS Author,
    U.Reputation,
    COALESCE(COUNT(C.CommentId), 0) AS CommentCount,
    COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty
FROM 
    TopPosts T
LEFT JOIN 
    Comments C ON T.PostID = C.PostId
LEFT JOIN 
    Votes V ON T.PostID = V.PostId AND V.VoteTypeId = 8
JOIN 
    Users U ON T.UserID = U.Id
GROUP BY 
    T.Title, T.Score, T.ViewCount, U.DisplayName, U.Reputation
HAVING 
    U.Reputation > 1000 AND 
    SUM(CASE WHEN C.Id IS NULL THEN 1 ELSE 0 END) > 0
ORDER BY 
    T.Score DESC, T.ViewCount DESC;
