
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
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.ViewCount DESC) AS RankByViewCount
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
),
PostStatistics AS (
    SELECT 
        PostId,
        Title,
        OwnerDisplayName,
        ViewCount,
        Score,
        AnswerCount,
        CommentCount,
        RANK() OVER (ORDER BY Score DESC) AS Rank
    FROM 
        RankedPosts
    WHERE 
        RankByScore <= 10
)
SELECT 
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.ViewCount,
    ps.Score,
    ps.AnswerCount,
    ps.CommentCount,
    CASE 
        WHEN ps.Rank <= 3 THEN 'Top Performer'
        WHEN ps.Rank <= 10 THEN 'Notable'
        ELSE 'Average'
    END AS PerformanceCategory
FROM 
    PostStatistics ps
ORDER BY 
    ps.Rank;
