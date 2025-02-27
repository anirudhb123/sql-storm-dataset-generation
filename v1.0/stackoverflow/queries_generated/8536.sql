WITH UserBadges AS (
    SELECT 
        U.Id AS UserId, 
        U.DisplayName, 
        COUNT(B.Id) AS BadgeCount 
    FROM 
        Users U
    LEFT JOIN 
        Badges B ON U.Id = B.UserId
    WHERE 
        U.Reputation > 1000
    GROUP BY 
        U.Id, U.DisplayName
), 
TopPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.CreationDate, 
        P.Score, 
        P.ViewCount, 
        P.AnswerCount, 
        P.CommentCount, 
        U.DisplayName AS OwnerDisplayName 
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate > NOW() - INTERVAL '1 year'
    ORDER BY 
        P.Score DESC 
    LIMIT 10
), 
PostHistoryAnalysis AS (
    SELECT 
        PH.PostId, 
        P.Title, 
        P.OwnerDisplayName, 
        P.Score, 
        P.ViewCount, 
        PH.CreationDate AS HistoryDate, 
        PHT.Name AS HistoryType 
    FROM 
        PostHistory PH
    JOIN 
        Posts P ON PH.PostId = P.Id
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    WHERE 
        PH.CreationDate BETWEEN (SELECT MAX(HistoryDate) FROM PostHistory WHERE PostHistoryTypeId = 10) 
                              AND (SELECT MIN(HistoryDate) FROM PostHistory WHERE PostHistoryTypeId = 11)
)
SELECT 
    UB.UserId, 
    UB.DisplayName, 
    UB.BadgeCount, 
    TP.PostId, 
    TP.Title, 
    TP.CreationDate AS PostCreationDate, 
    TP.Score AS PostScore, 
    TP.ViewCount AS PostViewCount, 
    PH.HistoryDate, 
    PH.HistoryType 
FROM 
    UserBadges UB
JOIN 
    TopPosts TP ON UB.UserId = TP.OwnerDisplayName
LEFT JOIN 
    PostHistoryAnalysis PH ON TP.PostId = PH.PostId
ORDER BY 
    UB.BadgeCount DESC, TP.Score DESC;
