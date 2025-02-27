-- Benchmarking string processing in the StackOverflow schema
WITH PostTagCounts AS (
    SELECT 
        PostId,
        COUNT(DISTINCT TRIM(SPLIT_PART(tag, '>', 1))) AS UniqueTagCount
    FROM 
        Posts, 
        LATERAL UNNEST(STRING_TO_ARRAY(SUBSTRING(Tags, 2, LENGTH(Tags) - 2), '><')) AS tag
    GROUP BY 
        PostId
),
PostViewsAndScores AS (
    SELECT 
        P.Id AS PostId,
        P.ViewCount,
        P.Score,
        P.Title,
        P.OwnerUserId,
        UTC_TIMESTAMP() AS CurrentTimestamp
    FROM 
        Posts P
    WHERE 
        P.CreationDate > CURRENT_DATE - INTERVAL '30 days'
)
SELECT 
    U.DisplayName AS Author,
    PVC.PostId,
    PVC.Title,
    PVC.ViewCount,
    PVC.Score,
    PTC.UniqueTagCount,
    CASE 
        WHEN PVC.Score > 100 THEN 'High Scoring'
        WHEN PVC.Score BETWEEN 50 AND 100 THEN 'Moderate Scoring'
        ELSE 'Low Scoring'
    END AS ScoreCategory,
    CASE 
        WHEN PVC.ViewCount > 500 THEN 'Highly Viewed'
        ELSE 'Less Viewed'
    END AS ViewCategory,
    CONCAT('Posted on ', TO_CHAR(PVC.CurrentTimestamp, 'YYYY-MM-DD'), ' | Tag Count: ', PTC.UniqueTagCount) AS Summary
FROM 
    PostViewsAndScores PVC
JOIN 
    Users U ON PVC.OwnerUserId = U.Id
JOIN 
    PostTagCounts PTC ON PVC.PostId = PTC.PostId
ORDER BY 
    PVC.Score DESC, PVC.ViewCount DESC
LIMIT 10;
