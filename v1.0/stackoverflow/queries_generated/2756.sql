WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        P.ViewCount,
        P.Score,
        U.DisplayName AS Author,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY P.Score DESC) AS Rank
    FROM 
        Posts P
    JOIN 
        Users U ON P.OwnerUserId = U.Id
    WHERE 
        P.CreationDate >= NOW() - INTERVAL '1 year'
),
PostTags AS (
    SELECT 
        P.Id AS PostId,
        STRING_AGG(T.TagName, ', ') AS Tags
    FROM 
        Posts P
    JOIN 
        UNNEST(string_to_array(TRIM(BOTH '{}' FROM P.Tags), '><')) AS Tag ON TRUE
    JOIN 
        Tags T ON T.TagName = Tag
    GROUP BY 
        P.Id
),
ClosedPosts AS (
    SELECT 
        PH.PostId,
        COUNT(*) AS CloseCount
    FROM 
        PostHistory PH
    WHERE 
        PH.PostHistoryTypeId = 10
    GROUP BY 
        PH.PostId
)
SELECT 
    RP.PostId,
    RP.Title,
    RP.CreationDate,
    RP.ViewCount,
    RP.Score,
    RP.Author,
    PT.Tags,
    COALESCE(CP.CloseCount, 0) AS CloseCount
FROM 
    RankedPosts RP
LEFT JOIN 
    PostTags PT ON RP.PostId = PT.PostId
LEFT JOIN 
    ClosedPosts CP ON RP.PostId = CP.PostId
WHERE 
    RP.Rank <= 5
ORDER BY 
    RP.Score DESC, RP.ViewCount DESC;

SELECT 
    * 
FROM 
    Posts 
WHERE 
    Id IN (SELECT DISTINCT ParentId FROM Posts WHERE ParentId IS NOT NULL) 
    AND Title ILIKE '%SQL%'
UNION 
SELECT 
    P.Id, P.Title, P.CreationDate, P.ViewCount 
FROM 
    Posts P 
WHERE 
    EXISTS (
        SELECT 1 
        FROM Votes V 
        WHERE V.PostId = P.Id 
        AND V.VoteTypeId = 2
    ) 
    AND P.Score < (SELECT AVG(Score) FROM Posts);
