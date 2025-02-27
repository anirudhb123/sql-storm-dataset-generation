WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY pt.Name ORDER BY p.CreationDate DESC) AS rn,
        COUNT(DISTINCT c.Id) OVER (PARTITION BY p.Id) AS CommentCount,
        SUM(v.BountyAmount) OVER (PARTITION BY p.Id) AS TotalBounty
    FROM 
        Posts p
    INNER JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE()) -- Posts created in the last year
),

FilteredPosts AS (
    SELECT 
        rp.*,
        COALESCE(u.DisplayName, 'Anonymous') AS OwnerDisplayName
    FROM 
        RankedPosts rp
    LEFT JOIN 
        Users u ON u.Id = p.OwnerUserId
    WHERE 
        rp.rn = 1 AND                     -- Getting the latest post for each PostType
        rp.Score > 0                      -- Only consider posts with a score greater than zero
),

TopPosts AS (
    SELECT 
        fp.PostId,
        fp.Title,
        fp.CreationDate,
        fp.ViewCount,
        fp.CommentCount,
        fp.TotalBounty,
        RANK() OVER (ORDER BY fp.TotalBounty DESC) AS BountyRank
    FROM 
        FilteredPosts fp
    WHERE 
        fp.CommentCount > 5               -- Only consider posts with more than 5 comments
)

SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.CommentCount,
    tp.TotalBounty,
    tp.BountyRank,
    pm.Name AS PostTypeName
FROM 
    TopPosts tp
INNER JOIN 
    PostTypes pm ON tp.PostId = pm.Id
WHERE 
    tp.BountyRank <= 10                  -- Getting top 10 posts by bounty
ORDER BY 
    tp.TotalBounty DESC;

-- This query benchmarks the performance by combining several SQL constructs:
-- 1. Common Table Expressions (CTEs) for modular organization.
-- 2. Window functions for ranking and calculations.
-- 3. Outer joins and subqueries to gather related data.
-- 4. Filtering conditions to focus on high-quality posts.
