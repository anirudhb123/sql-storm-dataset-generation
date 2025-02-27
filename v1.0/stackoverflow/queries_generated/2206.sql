WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        U.DisplayName AS OwnerDisplayName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankScore,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Users U ON p.OwnerUserId = U.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY 
        p.Id, U.DisplayName
),
PostStats AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.OwnerDisplayName,
        rp.Score,
        rp.ViewCount,
        rp.CommentCount,
        CASE 
            WHEN rp.RankScore = 1 THEN 'Top Post'
            WHEN rp.RankScore BETWEEN 2 AND 5 THEN 'High Performer'
            ELSE 'Regular Post'
        END AS PostCategory
    FROM 
        RankedPosts rp
)
SELECT 
    ps.OwnerDisplayName,
    COUNT(ps.Id) AS TotalPosts,
    SUM(ps.ViewCount) AS TotalViews,
    AVG(ps.Score) AS AverageScore,
    STRING_AGG(DISTINCT ps.PostCategory, ', ') AS Categories
FROM 
    PostStats ps
JOIN 
    Badges b ON ps.OwnerDisplayName = b.UserId
WHERE 
    b.Date >= NOW() - INTERVAL '6 months'
GROUP BY 
    ps.OwnerDisplayName
ORDER BY 
    TotalPosts DESC
LIMIT 10;

-- Benchmarking related queries
SELECT 
    p.Title,
    COALESCE(ph.Text, 'No history') AS PostHistory,
    pl.CreationDate AS RelatedPostDate,
    lt.Name AS LinkType
FROM 
    Posts p
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
LEFT JOIN 
    PostLinks pl ON p.Id = pl.PostId
LEFT JOIN 
    LinkTypes lt ON pl.LinkTypeId = lt.Id
WHERE 
    (ph.PostHistoryTypeId IN (10, 11) OR ph.PostHistoryTypeId IS NULL)
    AND (p.Score > 0 AND p.ViewCount < 100)
ORDER BY 
    p.LastActivityDate DESC
FETCH FIRST 5 ROWS ONLY;

