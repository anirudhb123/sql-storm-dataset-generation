
WITH UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        U.Reputation,
        @row_number := @row_number + 1 AS ReputationRank
    FROM 
        Users U, (SELECT @row_number := 0) AS init
    WHERE 
        U.Reputation > 0
    ORDER BY 
        U.Reputation DESC
),
PostsWithDetails AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Score,
        P.ViewCount,
        COALESCE(P.CreationDate, '1970-01-01') AS CreationDate,
        U.DisplayName AS OwnerDisplayName,
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS TotalComments,
        COUNT(CASE WHEN A.Id IS NOT NULL THEN 1 END) AS TotalAnswers
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON C.PostId = P.Id
    LEFT JOIN 
        Posts A ON A.ParentId = P.Id AND A.PostTypeId = 2
    WHERE 
        P.CreationDate > NOW() - INTERVAL 1 YEAR
    GROUP BY 
        P.Id, P.Title, P.Score, P.ViewCount, U.DisplayName
),
PostHistoryCounts AS (
    SELECT 
        PH.PostId,
        COUNT(PH.Id) AS HistoryCount,
        MAX(PH.CreationDate) AS LastEditDate
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId IN (4, 5, 6)  
    GROUP BY 
        PH.PostId
)
SELECT 
    PWD.PostId,
    PWD.Title,
    PWD.Score,
    PWD.ViewCount,
    PWD.OwnerDisplayName,
    UR.ReputationRank,
    PHC.HistoryCount,
    PHC.LastEditDate,
    CASE 
        WHEN PWD.TotalComments > 50 THEN 'High' 
        WHEN PWD.TotalComments BETWEEN 20 AND 50 THEN 'Medium' 
        ELSE 'Low' 
    END AS CommentLevel,
    CASE 
        WHEN PWD.TotalAnswers > 10 THEN 'Popular' 
        ELSE 'Normal' 
    END AS AnswerLevel
FROM 
    PostsWithDetails PWD
LEFT JOIN 
    UserReputation UR ON PWD.OwnerDisplayName = UR.DisplayName
LEFT JOIN 
    PostHistoryCounts PHC ON PWD.PostId = PHC.PostId
WHERE 
    PWD.Score > 0
    AND PWD.ViewCount > 100
    AND PHC.HistoryCount IS NOT NULL
ORDER BY 
    UR.ReputationRank, PWD.Score DESC;
