
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId, 
        P.Title, 
        P.Body, 
        U.DisplayName AS OwnerName, 
        P.CreationDate, 
        P.Score, 
        COUNT(CASE WHEN C.Id IS NOT NULL THEN 1 END) AS CommentCount,
        GROUP_CONCAT(DISTINCT T.TagName ORDER BY T.TagName SEPARATOR ', ') AS TagsList
    FROM 
        Posts P
    LEFT JOIN 
        Users U ON P.OwnerUserId = U.Id
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        (SELECT DISTINCT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(P.Tags, '<>', numbers.n), '<>', -1)) AS TagName
         FROM 
         (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
          SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers
         WHERE CHAR_LENGTH(P.Tags) - CHAR_LENGTH(REPLACE(P.Tags, '<>', '')) >= numbers.n - 1) AS T ON TRUE
    WHERE 
        P.PostTypeId = 1  
    GROUP BY 
        P.Id, P.Title, P.Body, U.DisplayName, P.CreationDate, P.Score
),
PostHistoryContent AS (
    SELECT 
        PH.PostId,
        GROUP_CONCAT(PH.CreationDate ORDER BY PH.CreationDate SEPARATOR ', ') AS RevisionDates,
        GROUP_CONCAT(PHT.Name ORDER BY PHT.Name SEPARATOR ', ') AS HistoryTypes,
        MAX(PH.CreationDate) AS LastModifiedDate
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
EnhancedPosts AS (
    SELECT 
        RP.*, 
        PHC.RevisionDates, 
        PHC.HistoryTypes,
        PHC.LastModifiedDate
    FROM 
        RankedPosts RP
    LEFT JOIN 
        PostHistoryContent PHC ON RP.PostId = PHC.PostId
)
SELECT 
    EP.PostId,
    EP.Title,
    EP.OwnerName,
    EP.CreationDate,
    EP.Score,
    EP.CommentCount,
    EP.TagsList,
    EP.RevisionDates,
    EP.HistoryTypes,
    EP.LastModifiedDate,
    CASE 
        WHEN EP.Score >= 10 THEN 'High Score'
        WHEN EP.Score BETWEEN 5 AND 9 THEN 'Moderate Score'
        ELSE 'Low Score' 
    END AS ScoreCategory
FROM 
    EnhancedPosts EP
WHERE 
    EP.LastModifiedDate >= NOW() - INTERVAL 30 DAY
ORDER BY 
    EP.Score DESC, 
    EP.CommentCount DESC;
