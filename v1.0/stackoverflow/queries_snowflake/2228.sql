
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS PostRank,
        P.OwnerUserId
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        P.CreationDate >= DATEADD(year, -1, CURRENT_DATE)
    GROUP BY 
        P.Id, P.Title, P.CreationDate, P.Score, P.OwnerUserId
),
UserBadges AS (
    SELECT 
        U.Id AS UserId,
        COUNT(CASE WHEN B.Class = 1 THEN 1 END) AS GoldCount,
        COUNT(CASE WHEN B.Class = 2 THEN 1 END) AS SilverCount,
        COUNT(CASE WHEN B.Class = 3 THEN 1 END) AS BronzeCount
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id
),
TopUsers AS (
    SELECT 
        U.Id,
        U.DisplayName,
        U.Reputation,
        UBad.GoldCount,
        UBad.SilverCount,
        UBad.BronzeCount,
        R.PostRank,
        R.PostId
    FROM 
        Users U
    JOIN 
        UserBadges UBad ON U.Id = UBad.UserId
    LEFT JOIN 
        RankedPosts R ON U.Id = R.OwnerUserId
    WHERE 
        U.Reputation > 1000
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(R.PostId, -1) AS MostRecentPost,
    COALESCE(R.Title, 'No Posts') AS LatestPostTitle,
    COALESCE(R.CommentCount, 0) AS CommentsOnLatestPost,
    LISTAGG(CASE WHEN B.Class = 1 THEN 'Gold' WHEN B.Class = 2 THEN 'Silver' WHEN B.Class = 3 THEN 'Bronze' END, ', ') 
     WITHIN GROUP (ORDER BY B.Class) AS BadgeList
FROM 
    Users U
LEFT JOIN 
    TopUsers T ON U.Id = T.Id
LEFT JOIN 
    RankedPosts R ON T.PostId = R.PostId
LEFT JOIN 
    Badges B ON U.Id = B.UserId
WHERE 
    T.PostRank IS NULL OR T.PostRank <= 5
GROUP BY 
    U.DisplayName, U.Reputation, R.PostId, R.Title, R.CommentCount, T.PostRank
ORDER BY 
    U.Reputation DESC, U.DisplayName ASC;
