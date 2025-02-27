WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Body,
        P.CreationDate,
        U.DisplayName AS OwnerDisplayName,
        P.ViewCount,
        P.Score,
        RANK() OVER (PARTITION BY P.OwnerUserId ORDER BY P.Score DESC) AS RankByScore
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.PostTypeId IN (1, 2) -- Questions and Answers
        AND P.CreationDate >= NOW() - INTERVAL '1 year' -- Within the last year
),
LatestPostHistory AS (
    SELECT 
        PH.PostId,
        PH.CreationDate AS HistoryCreationDate,
        PH.UserDisplayName AS EditorDisplayName,
        PH.Comment,
        PH.Text
    FROM 
        PostHistory PH
    JOIN 
        RankedPosts RP ON PH.PostId = RP.PostId
    WHERE 
        PH.CreationDate = (
            SELECT MAX(CreationDate) 
            FROM PostHistory 
            WHERE PostId = RP.PostId
        )
),
TopUsers AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(DISTINCT P.Id) AS PostCount,
        SUM(CASE WHEN (P.Score > 0) THEN 1 ELSE 0 END) AS PositivePostCount,
        SUM(CASE WHEN (P.Score < 0) THEN 1 ELSE 0 END) AS NegativePostCount
    FROM 
        Users U
    JOIN 
        Posts P ON U.Id = P.OwnerUserId
    WHERE 
        P.PostTypeId = 1 -- Questions
    GROUP BY 
        U.Id
    HAVING 
        COUNT(DISTINCT P.Id) >= 5 -- Users with at least 5 questions
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.Body,
    RP.CreationDate,
    RP.OwnerDisplayName,
    RP.ViewCount,
    RP.Score,
    LPH.EditorDisplayName,
    LPH.HistoryCreationDate,
    LPH.Comment,
    LPH.Text,
    TU.DisplayName AS TopUserName,
    TU.PostCount,
    TU.PositivePostCount,
    TU.NegativePostCount
FROM 
    RankedPosts RP
LEFT JOIN 
    LatestPostHistory LPH ON RP.PostId = LPH.PostId
LEFT JOIN 
    TopUsers TU ON RP.OwnerUserId = TU.UserId
WHERE 
    RP.RankByScore <= 5 -- Top 5 posts by score per user
ORDER BY 
    RP.OwnerDisplayName, RP.Score DESC;
