WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.AnswerCount,
        p.CommentCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 YEAR'
),
AggregatedScores AS (
    SELECT 
        pt.Name AS PostType,
        COUNT(*) AS TotalPosts,
        SUM(rp.Score) AS TotalScore,
        AVG(rp.ViewCount) AS AverageViewCount,
        AVG(rp.AnswerCount) AS AverageAnswerCount,
        AVG(rp.CommentCount) AS AverageCommentCount
    FROM 
        RankedPosts rp
    JOIN 
        PostTypes pt ON rp.PostId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    as.PostType,
    as.TotalPosts,
    as.TotalScore,
    as.AverageViewCount,
    as.AverageAnswerCount,
    as.AverageCommentCount
FROM 
    AggregatedScores as
WHERE 
    as.TotalPosts > 10
ORDER BY 
    as.TotalScore DESC, 
    as.AverageViewCount DESC;
