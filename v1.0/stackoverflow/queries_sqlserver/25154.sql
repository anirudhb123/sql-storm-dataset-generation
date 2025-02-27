
WITH PostTagCounts AS (
    SELECT 
        p.Id AS PostId,
        COUNT(DISTINCT t.TagName) AS UniqueTagCount,
        SUM(LEN(p.Body) - LEN(REPLACE(p.Body, ' ', ''))) + 1 AS WordCount
    FROM 
        Posts p
    OUTER APPLY (
        SELECT value AS TagName
        FROM STRING_SPLIT(SUBSTRING(p.Tags, 2, LEN(p.Tags) - 2), '> <')
    ) AS t
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
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
