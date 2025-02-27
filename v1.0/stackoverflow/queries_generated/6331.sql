WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        COUNT(P.Id) AS PostCount,
        COUNT(DISTINCT B.Id) AS BadgeCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id
), 
TopPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.Score,
        P.ViewCount,
        U.DisplayName AS OwnerName
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId = 1 AND P.Score > 10
    ORDER BY 
        P.Score DESC
    LIMIT 5
),
PostDetails AS (
    SELECT 
        TH.PostId,
        TH.UserId AS EditorId,
        U.DisplayName AS EditorName,
        MAX(TH.CreationDate) AS LastEditDate,
        COUNT(CASE WHEN TH.PostHistoryTypeId IN (10, 11) THEN 1 END) AS CloseReopenCount
    FROM 
        PostHistory TH
    JOIN 
        Posts P ON TH.PostId = P.Id
    JOIN 
        Users U ON TH.UserId = U.Id
    WHERE 
        TH.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    GROUP BY 
        TH.PostId, TH.UserId
)
SELECT 
    UR.DisplayName AS UserName,
    UR.Reputation,
    UR.PostCount,
    UR.BadgeCount,
    TP.Title AS TopPostTitle,
    TP.CreationDate AS TopPostDate,
    TP.Score AS TopPostScore,
    TP.ViewCount AS TopPostViews,
    PD.LastEditDate,
    PD.EditorName,
    PD.CloseReopenCount
FROM 
    UserReputation UR
JOIN 
    TopPosts TP ON UR.PostCount > 0
JOIN 
    PostDetails PD ON TP.PostId = PD.PostId
ORDER BY 
    UR.Reputation DESC, TP.Score DESC;
