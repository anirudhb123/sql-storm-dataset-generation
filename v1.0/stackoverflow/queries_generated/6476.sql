WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())
),
TopUserPosts AS (
    SELECT 
        pp.PostId,
        pp.Title,
        pp.CreationDate,
        pp.Score,
        pp.ViewCount,
        pp.AnswerCount,
        pp.CommentCount,
        pp.OwnerDisplayName
    FROM 
        RankedPosts pp
    WHERE 
        pp.PostRank = 1
)
SELECT 
    t.TagName,
    COUNT(DISTINCT tup.PostId) AS PostCount,
    SUM(tup.ViewCount) AS TotalViews,
    AVG(tup.Score) AS AverageScore,
    SUM(tup.AnswerCount) AS TotalAnswers,
    SUM(tup.CommentCount) AS TotalComments
FROM 
    TopUserPosts tup
JOIN 
    unnest(string_to_array(tup.Tags, ',')) AS t(TagName) ON t.TagName IS NOT NULL
GROUP BY 
    t.TagName
ORDER BY 
    TotalViews DESC, PostCount DESC
LIMIT 10;
