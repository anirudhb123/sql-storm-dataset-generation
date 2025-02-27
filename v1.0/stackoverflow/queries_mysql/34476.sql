
WITH RECURSIVE UserActivity AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN P.Score < 0 THEN 1 ELSE 0 END) AS NegativePostCount,
        COALESCE(SUM(UP.VoteCount), 0) AS TotalVotes
    FROM 
        Users U
    LEFT JOIN 
        (
            SELECT 
                P.OwnerUserId,
                P.Id,
                P.Score,
                COUNT(V.Id) AS VoteCount
            FROM 
                Posts P
            LEFT JOIN 
                Votes V ON V.PostId = P.Id
            WHERE 
                P.CreationDate >= NOW() - INTERVAL 1 YEAR
            GROUP BY 
                P.OwnerUserId, P.Id
        ) UP ON UP.OwnerUserId = U.Id
    LEFT JOIN 
        Posts P ON P.OwnerUserId = U.Id
    GROUP BY 
        U.Id, U.DisplayName
), UserBadges AS (
    SELECT 
        B.UserId,
        COUNT(B.Id) AS BadgeCount,
        GROUP_CONCAT(B.Name SEPARATOR ', ') AS BadgeNames
    FROM 
        Badges B
    GROUP BY 
        B.UserId
), PostsRanked AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.OwnerUserId,
        @rank := IF(@prevOwner = P.OwnerUserId, @rank + 1, 1) AS PostRank,
        @prevOwner := P.OwnerUserId
    FROM 
        Posts P, (SELECT @rank := 0, @prevOwner := NULL) AS vars
    ORDER BY 
        P.OwnerUserId, P.CreationDate DESC
)
SELECT 
    UA.UserId,
    UA.DisplayName,
    UA.PostCount,
    UA.PositivePostCount,
    UA.NegativePostCount,
    UA.TotalVotes,
    UB.BadgeCount,
    UB.BadgeNames,
    P.PostId,
    P.Title,
    P.Score,
    P.PostRank
FROM 
    UserActivity UA
LEFT JOIN 
    UserBadges UB ON UA.UserId = UB.UserId
LEFT JOIN 
    PostsRanked P ON UA.UserId = P.OwnerUserId AND P.PostRank <= 3  
WHERE 
    UA.PostCount > 10
ORDER BY 
    UA.TotalVotes DESC, 
    UA.PostCount DESC;
