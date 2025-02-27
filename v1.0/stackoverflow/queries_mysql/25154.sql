
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount,
        SUM(CHAR_LENGTH(p.Body) - CHAR_LENGTH(REPLACE(p.Body, ' ', ''))) + 1 AS WordCount
    FROM 
        Posts p
    LEFT JOIN 
        (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', n.n), '<', -1)) AS TagName 
         FROM Posts p JOIN (SELECT a.N + b.N * 10 + 1 n FROM 
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
           SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
           SELECT 8 UNION ALL SELECT 9) a CROSS JOIN 
          (SELECT 0 AS N UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
           SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL 
           SELECT 8 UNION ALL SELECT 9) b) n 
         WHERE n.n <= CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '>', '')) + 1) AS t 
         ON TRUE
    WHERE 
        p.PostTypeId = 1 
    GROUP BY 
        p.Id
),
HighTagWordCountPosts AS (
    SELECT 
        ptc.PostId,
        ptc.UniqueTagCount,
        ptc.WordCount,
        p.Title,
        p.Score,
        u.DisplayName AS OwnerDisplayName
    FROM 
        PostTagCounts ptc
    JOIN 
        Posts p ON ptc.PostId = p.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        ptc.UniqueTagCount > 5 AND ptc.WordCount > 100
),
MostCommentedPosts AS (
    SELECT 
        PostId,
        COUNT(*) AS CommentCount
    FROM 
        Comments
    GROUP BY 
        PostId
    HAVING 
        COUNT(*) >= 5
),
FinalBenchmarkResults AS (
    SELECT 
        h.Title,
        h.OwnerDisplayName,
        h.UniqueTagCount,
        h.WordCount,
        COALESCE(mc.CommentCount, 0) AS TotalComments
    FROM 
        HighTagWordCountPosts h
    LEFT JOIN 
        MostCommentedPosts mc ON h.PostId = mc.PostId
)
SELECT 
    *,
    RANK() OVER (ORDER BY TotalComments DESC, UniqueTagCount DESC) AS PostRank
FROM 
    FinalBenchmarkResults
ORDER BY 
    PostRank
LIMIT 10;
