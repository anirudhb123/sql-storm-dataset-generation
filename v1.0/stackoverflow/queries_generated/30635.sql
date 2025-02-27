WITH RECURSIVE UserReputation AS (
    SELECT 
        U.Id AS UserId,
        U.Reputation,
        0 AS Level
    FROM 
        Users U
    WHERE 
        U.Reputation IS NOT NULL
    UNION ALL
    SELECT 
        U.Id,
        U.Reputation,
        UR.Level + 1
    FROM 
        Users U
    JOIN 
        UserReputation UR ON U.Id = UR.UserId
    WHERE 
        U.Reputation < UR.Reputation
),
PopularTags AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount
    FROM 
        Tags T
    JOIN 
        Posts P ON P.Tags LIKE '%' || T.TagName || '%'
    GROUP BY 
        T.TagName
    HAVING 
        COUNT(P.Id) > 10
),
RecentPosts AS (
    SELECT 
        P.Id,
        P.Title,
        P.CreationDate,
        P.Score,
        U.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY P.OwnerUserId ORDER BY P.CreationDate DESC) AS rn
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '30 days'
    AND 
        P.Score > 0
    ORDER BY 
        P.CreationDate DESC
),
PostHistorySummary AS (
    SELECT 
        PH.PostId,
        MAX(PH.CreationDate) AS LastEditDate,
        COUNT(PH.Id) AS EditCount,
        STRING_AGG(DISTINCT PHT.Name, ', ') AS EditTypes
    FROM 
        PostHistory PH
    JOIN 
        PostHistoryTypes PHT ON PH.PostHistoryTypeId = PHT.Id
    GROUP BY 
        PH.PostId
),
FinalResult AS (
    SELECT 
        RP.Title,
        RP.CreationDate,
        RP.Score,
        RP.OwnerDisplayName,
        COALESCE(PHS.LastEditDate, 'No edits') AS LastEdit,
        COALESCE(PHS.EditCount, 0) AS TotalEditCount,
        COALESCE(PHS.EditTypes, 'No changes') AS EditTypes,
        T.TagName,
        UR.Reputation AS UserReputation
    FROM 
        RecentPosts RP
    LEFT JOIN 
        PostHistorySummary PHS ON RP.Id = PHS.PostId
    JOIN 
        Users U ON RP.OwnerDisplayName = U.DisplayName
    CROSS JOIN 
        (SELECT DISTINCT TagName FROM PopularTags) T
    LEFT JOIN 
        UserReputation UR ON UR.UserId = U.Id
)
SELECT 
    *,
    CONCAT('Post by ', OwnerDisplayName, ' is about ', TagName) AS Description
FROM 
    FinalResult
WHERE 
    UserReputation > 100
ORDER BY 
    Score DESC, LastEdit DESC;
