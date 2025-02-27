
WITH RankedPosts AS (
    SELECT 
        P.Id AS PostId,
        P.Title,
        P.Tags,
        COUNT(DISTINCT C.Id) AS CommentCount,
        COUNT(DISTINCT A.Id) AS AnswerCount,
        COALESCE(SUM(V.BountyAmount), 0) AS TotalBounty,
        100.0 * COUNT(DISTINCT C.Id) / NULLIF(COUNT(DISTINCT A.Id), 0) AS CommentToAnswerRatio,
        ROW_NUMBER() OVER (PARTITION BY P.PostTypeId ORDER BY COUNT(DISTINCT C.Id) DESC) AS Rank
    FROM 
        Posts P
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    LEFT JOIN 
        Posts A ON P.Id = A.ParentId AND A.PostTypeId = 2 
    LEFT JOIN 
        Votes V ON P.Id = V.PostId AND V.VoteTypeId IN (8, 9) 
    GROUP BY 
        P.Id, P.Title, P.Tags
),
FilteredPosts AS (
    SELECT 
        PostId, 
        Title, 
        Tags, 
        CommentCount, 
        AnswerCount, 
        TotalBounty, 
        CommentToAnswerRatio
    FROM 
        RankedPosts
    WHERE 
        Rank <= 10
)

SELECT 
    FP.PostId,
    FP.Title,
    GROUP_CONCAT(T.TagName SEPARATOR ', ') AS RelatedTags,
    FP.CommentCount,
    FP.AnswerCount,
    FP.TotalBounty,
    FP.CommentToAnswerRatio
FROM 
    FilteredPosts FP
LEFT JOIN 
    (SELECT TRIM(SUBSTRING_INDEX(SUBSTRING_INDEX(FP.Tags, '<>', n.n), '<>', -1)) AS Tag
     FROM (SELECT 1 n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION 
           SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) n 
     WHERE n.n <= (LENGTH(FP.Tags) - LENGTH(REPLACE(FP.Tags, '<>', '')) + 1)
    ) AS Tag ON Tag IS NOT NULL
LEFT JOIN 
    Tags T ON T.TagName = Tag
GROUP BY 
    FP.PostId, FP.Title, FP.CommentCount, FP.AnswerCount, FP.TotalBounty, FP.CommentToAnswerRatio
ORDER BY 
    FP.TotalBounty DESC, 
    FP.CommentCount DESC;
