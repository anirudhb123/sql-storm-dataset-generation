WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        SUM(CASE WHEN P.ViewCount > 1000 THEN 1 ELSE 0 END) AS PopularPosts,
        AVG(P.Score) AS AverageScore
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(B.Id) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
),
PostStats AS (
    SELECT 
        P.Id AS PostId,
        P.OwnerUserId,
        P.PostTypeId,
        P.CreationDate,
        COUNT(C.Id) AS CommentCount,
        SUM(V.VoteTypeId = 2) AS Upvotes,
        SUM(V.VoteTypeId = 3) AS Downvotes,
        (SELECT COUNT(*) FROM Votes V2 WHERE V2.PostId = P.Id AND V2.VoteTypeId = 6) AS CloseVotes
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Votes V ON P.Id = V.PostId
    GROUP BY 
        P.Id, P.OwnerUserId, P.PostTypeId, P.CreationDate
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(TB.BadgeNames, 'None') AS BadgeNames,
    UR.TotalPosts,
    UR.PopularPosts,
    UR.AverageScore,
    PS.CommentCount,
    PS.Upvotes,
    PS.Downvotes,
    PS.CloseVotes
FROM 
    UserReputation UR
LEFT JOIN 
    TopBadges TB ON UR.UserId = TB.UserId
JOIN 
    PostStats PS ON UR.UserId = PS.OwnerUserId
WHERE 
    UR.Reputation > 500
ORDER BY 
    UR.Reputation DESC,
    PS.Upvotes DESC
LIMIT 10;
