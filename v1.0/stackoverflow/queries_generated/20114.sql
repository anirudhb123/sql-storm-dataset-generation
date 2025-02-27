WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankScore,
        DENSE_RANK() OVER (ORDER BY p.CreationDate DESC) AS RankDate,
        COALESCE(c.CommentCount, 0) AS TotalComments
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        (SELECT PostId, COUNT(*) AS CommentCount FROM Comments GROUP BY PostId) AS c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
        AND p.Score IS NOT NULL
),
FilteredPosts AS (
    SELECT 
        rp.*,
        CASE 
            WHEN rp.RankScore = 1 THEN 'Top Post'
            WHEN rp.RankScore <= 5 THEN 'Top 5'
            ELSE 'Other Post'
        END AS RankCategory,
        CASE 
            WHEN rp.TotalComments > 5 THEN 'Highly Discussed'
            ELSE 'Less Discussed'
        END AS DiscussionLevel
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankDate <= 10
),
PostsWithHistory AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.Score,
        fp.OwnerDisplayName,
        fp.RankCategory,
        fp.DiscussionLevel,
        ph.PostHistoryTypeId,
        ph.CreationDate AS HistoryCreationDate,
        ph.Comment
    FROM 
        FilteredPosts fp
    LEFT JOIN 
        PostHistory ph ON fp.PostId = ph.PostId
    WHERE 
        ph.CreationDate = (SELECT MAX(CreationDate) FROM PostHistory WHERE PostId = fp.PostId)
    AND 
        ph.Comment IS NOT NULL
)
SELECT 
    pwh.PostId,
    pwh.Title,
    pwh.CreationDate,
    pwh.ViewCount,
    pwh.Score,
    pwh.OwnerDisplayName,
    pwh.RankCategory,
    pwh.DiscussionLevel,
    COUNT(DISTINCT v.Id) AS TotalVotes,
    STRING_AGG(DISTINCT ph.Comment, '; ') AS LastComments
FROM 
    PostsWithHistory pwh
LEFT JOIN 
    Votes v ON pwh.PostId = v.PostId
WHERE 
    pwh.Score > (SELECT AVG(Score) FROM Posts)
GROUP BY 
    pwh.PostId, pwh.Title, pwh.CreationDate, pwh.ViewCount, pwh.Score, pwh.OwnerDisplayName, pwh.RankCategory, pwh.DiscussionLevel
HAVING 
    COUNT(DISTINCT v.Id) > 0
ORDER BY 
    pwh.ViewCount DESC, pwh.Score DESC
LIMIT 100;

This SQL query features various elements such as Common Table Expressions (CTEs), window functions, outer joins, correlated subqueries, string aggregation, and advanced filtering and ranking, all while incorporating complex predicates and expressions to create a rich data set for performance benchmarking.
