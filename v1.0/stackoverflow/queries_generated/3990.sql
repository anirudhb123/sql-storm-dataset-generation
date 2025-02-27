WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(DISTINCT P.Id) AS TotalPosts,
        COUNT(DISTINCT C.Id) AS TotalComments
    FROM 
        Users U
    LEFT OUTER JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT OUTER JOIN 
        Comments C ON U.Id = C.UserId
    GROUP BY 
        U.Id, U.DisplayName, U.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        Reputation,
        TotalPosts,
        TotalComments,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserReputation
),
UserBadges AS (
    SELECT 
        B.UserId,
        STRING_AGG(B.Name, ', ') AS BadgeNames,
        COUNT(*) AS BadgeCount
    FROM 
        Badges B
    GROUP BY 
        B.UserId
)
SELECT 
    U.DisplayName,
    U.Reputation,
    COALESCE(UB.BadgeNames, 'No Badges') AS Badges,
    COALESCE(UB.BadgeCount, 0) AS TotalBadges,
    U.TotalPosts,
    U.TotalComments
FROM 
    TopUsers U
LEFT JOIN 
    UserBadges UB ON U.UserId = UB.UserId
WHERE 
    U.ReputationRank <= 10
ORDER BY 
    U.Reputation DESC
LIMIT 10;

WITH RecentPostHistory AS (
    SELECT 
        PH.PostId,
        PH.UserId,
        PH.CreationDate,
        PHP.Name AS HistoryTypeName
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHP ON PH.PostHistoryTypeId = PHP.Id
    WHERE 
        PH.CreationDate >= NOW() - INTERVAL '30 days'
),
PostWithHistoryCount AS (
    SELECT 
        P.Id AS PostId,
        COUNT(RPH.UserId) AS RecentHistoryCount
    FROM 
        Posts P
    LEFT JOIN 
        RecentPostHistory RPH ON P.Id = RPH.PostId
    GROUP BY 
        P.Id
)
SELECT 
    P.Title,
    P.ViewCount,
    P.Score,
    COALESCE(PWH.RecentHistoryCount, 0) AS RecentHistoryActionCount
FROM 
    Posts P
LEFT JOIN 
    PostWithHistoryCount PWH ON P.Id = PWH.PostId
WHERE 
    P.AcceptedAnswerId IS NOT NULL
ORDER BY 
    P.Score DESC, P.ViewCount DESC
LIMIT 5;
