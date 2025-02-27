WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        p.PostTypeId,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS rn
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    WHERE 
        p.CreationDate >= DATEADD(year, -1, GETDATE())  -- Only consider posts created in the last year
),

PostHistoryStats AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEditedDate,
        STRING_AGG(CONVERT(varchar, ph.PostHistoryTypeId), ',') AS EditHistoryTypes
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
),

TopUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)

SELECT 
    rp.Title,
    rp.Score,
    rp.ViewCount,
    rp.CreationDate,
    ISNULL(ph.EditCount, 0) AS EditCount,
    ISNULL(ph.LastEditedDate, 'Never') AS LastEditedDate,
    ISNULL(TU.TotalPosts, 0) AS TotalPostsByUser,
    ISNULL(TU.PositivePosts, 0) AS PositivePostsByUser
FROM 
    RankedPosts rp
LEFT JOIN 
    PostHistoryStats ph ON rp.Id = ph.PostId
LEFT JOIN 
    TopUsers TU ON rp.OwnerUserId = TU.UserId
WHERE 
    rp.rn = 1  -- Selecting the top post by score for each user
ORDER BY 
    rp.Score DESC, 
    rp.CreationDate DESC;

WITH RECURSIVE RelatedPosts AS (
    SELECT 
        pl.RelatedPostId,
        pl.LinkTypeId
    FROM 
        PostLinks pl
    WHERE 
        pl.PostId = (SELECT TOP 1 Id FROM Posts ORDER BY CreationDate DESC)  -- Start with the most recent post
    UNION ALL
    SELECT 
        pl.RelatedPostId,
        pl.LinkTypeId
    FROM 
        PostLinks pl
    INNER JOIN 
        RelatedPosts rp ON pl.PostId = rp.RelatedPostId
)
SELECT 
    rp.RelatedPostId,
    COUNT(*) AS TotalRelated
FROM 
    RelatedPosts rp
GROUP BY 
    rp.RelatedPostId;

-- Performance benchmarking can be made by measuring the execution time of the above complex query 
-- compared to simpler queries that only access one or two tables without joins or subqueries.
