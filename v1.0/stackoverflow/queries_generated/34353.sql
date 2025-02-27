WITH RecursivePosts AS (
    SELECT 
        Id,
        Title,
        CreationDate,
        PostTypeId,
        ViewCount,
        Score,
        OwnerUserId,
        1 AS Level
    FROM Posts
    WHERE PostTypeId = 1  -- Start with Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.PostTypeId,
        p.ViewCount,
        p.Score,
        p.OwnerUserId,
        rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePosts rp ON p.ParentId = rp.Id
    WHERE p.PostTypeId = 2 -- Only include Answers
),
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(p.ViewCount) AS TotalViews
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId AND v.VoteTypeId = 9 -- BountyClose votes
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId 
    GROUP BY u.Id
),
FilteredPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        us.UserId,
        us.DisplayName,
        us.TotalBadges,
        us.TotalBounties,
        us.TotalPosts,
        us.TotalViews
    FROM RecursivePosts rp
    INNER JOIN UserStatistics us ON rp.OwnerUserId = us.UserId
    WHERE rp.Score > 0 -- Include only positive scored posts
),
PostHistoryAggregates AS (
    SELECT 
        ph.PostId,
        MAX(ph.CreationDate) AS LastEditDate,
        COUNT(*) AS TotalEdits,
        STRING_AGG(DISTINCT pht.Name, ', ') AS EditTypes
    FROM PostHistory ph
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY ph.PostId
)
SELECT 
    fp.Id AS PostId,
    fp.Title,
    fp.ViewCount,
    fp.Score,
    fp.DisplayName AS Owner,
    fp.TotalBadges,
    fp.TotalBounties,
    ph.LastEditDate,
    ph.TotalEdits,
    ph.EditTypes
FROM FilteredPosts fp
LEFT JOIN PostHistoryAggregates ph ON fp.Id = ph.PostId
WHERE (fp.TotalViews > 1000 OR ph.TotalEdits > 5) -- Filtering criteria
ORDER BY fp.ViewCount DESC, fp.Score DESC
OFFSET 0 ROWS FETCH NEXT 50 ROWS ONLY; -- Pagination for performance
