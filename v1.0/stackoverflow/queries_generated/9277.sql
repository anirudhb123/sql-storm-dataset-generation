WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        p.CommentCount,
        p.Tags,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        u.Reputation > 1000
        AND p.CreationDate >= '2023-01-01'
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.CommentCount,
        rp.Tags
    FROM 
        RankedPosts rp
    WHERE 
        rp.Rank <= 5
),
PostScoreStatistics AS (
    SELECT 
        tags.TagName,
        COUNT(tp.PostId) AS PostCount,
        AVG(tp.Score) AS AverageScore,
        SUM(tp.ViewCount) AS TotalViews,
        SUM(tp.AnswerCount) AS TotalAnswers,
        SUM(tp.CommentCount) AS TotalComments
    FROM 
        TopPosts tp
    CROSS JOIN 
        LATERAL unnest(string_to_array(tp.Tags, ',')) AS tags(TagName)
    GROUP BY 
        tags.TagName
)

SELECT 
    t.TagName,
    ps.PostCount,
    ps.AverageScore,
    ps.TotalViews,
    ps.TotalAnswers,
    ps.TotalComments
FROM 
    PostScoreStatistics ps
JOIN 
    Tags t ON ps.TagName = t.TagName
WHERE 
    t.IsModeratorOnly = 0
ORDER BY 
    ps.AverageScore DESC, ps.TotalViews DESC;
