
WITH KeywordCounts AS (
    SELECT 
        P.Id AS PostId,
        COUNT(*) AS KeywordCount,
        STRING_AGG(DISTINCT T.TagName, ', ') AS Tags
    FROM 
        Posts P
    CROSS APPLY (
        SELECT value AS TagName
        FROM STRING_SPLIT(SUBSTRING(P.Tags, 2, LEN(P.Tags) - 2), '>') 
    ) AS T
    WHERE 
        P.PostTypeId = 1 
    GROUP BY 
        P.Id
),
RecentVotes AS (
    SELECT 
        V.PostId,
        COUNT(V.Id) AS VoteCount
    FROM 
        Votes V
    WHERE 
        V.CreationDate >= DATEADD(DAY, -30, '2024-10-01 12:34:56')
    GROUP BY 
        V.PostId
),
PostStatistics AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.CreationDate,
        COALESCE(KC.KeywordCount, 0) AS KeywordCount,
        COALESCE(RV.VoteCount, 0) AS RecentVoteCount
    FROM 
        Posts P
    LEFT JOIN 
        KeywordCounts KC ON P.Id = KC.PostId
    LEFT JOIN 
        RecentVotes RV ON P.Id = RV.PostId
)
SELECT 
    PS.PostId,
    PS.Title,
    PS.CreationDate,
    PS.KeywordCount,
    PS.RecentVoteCount,
    CASE 
        WHEN PS.RecentVoteCount > 10 THEN 'Hot'
        WHEN PS.KeywordCount > 5 THEN 'Trending'
        ELSE 'Normal'
    END AS PostStatus
FROM 
    PostStatistics PS
WHERE 
    PS.KeywordCount > 0
ORDER BY 
    PS.RecentVoteCount DESC, 
    PS.KeywordCount DESC;
