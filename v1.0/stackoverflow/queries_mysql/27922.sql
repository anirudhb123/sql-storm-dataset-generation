
WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        p.Tags,
        p.OwnerUserId,
        @row_number := IF(@current_tag = Tag, @row_number + 1, 1) AS Rank,
        @current_tag := Tag
    FROM 
        Posts p,
        (SELECT @row_number := 0, @current_tag := '') AS vars,
        UNNEST(SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '>', 2), '<', -1)) AS Tag
    WHERE 
        p.PostTypeId = 1 
    ORDER BY 
        Tag, p.Score DESC
), 
TopRankedPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags,
        u.DisplayName AS OwnerName
    FROM 
        RankedPosts rp
    JOIN 
        Users u ON rp.OwnerUserId = u.Id
    WHERE 
        rp.Rank <= 5 
), 
PostStatistics AS (
    SELECT 
        Tag,
        COUNT(*) AS TotalPosts,
        AVG(ViewCount) AS AvgViews,
        SUM(CASE WHEN Score > 0 THEN 1 ELSE 0 END) AS PositiveScoreCount
    FROM 
        TopRankedPosts tp
    CROSS JOIN 
        UNNEST(SUBSTRING_INDEX(tp.Tags, '>', 2)) AS Tag
    GROUP BY 
        Tag
)

SELECT 
    ps.Tag,
    ps.TotalPosts,
    ps.AvgViews,
    ps.PositiveScoreCount,
    GROUP_CONCAT(tp.Title SEPARATOR '; ') AS TopPostTitles
FROM 
    PostStatistics ps
JOIN 
    TopRankedPosts tp ON tp.Tags LIKE CONCAT('%', ps.Tag, '%')
GROUP BY 
    ps.Tag, ps.TotalPosts, ps.AvgViews, ps.PositiveScoreCount
ORDER BY 
    ps.TotalPosts DESC, ps.AvgViews DESC;
