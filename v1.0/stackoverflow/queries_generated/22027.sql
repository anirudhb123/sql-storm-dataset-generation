WITH RankedPosts AS (
    SELECT 
        p.Id as PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) as Rnk
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id as UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) as TotalViews,
        COUNT(DISTINCT p.Id) as PostedCount,
        AVG(COALESCE(v.BountyAmount, 0)) as AvgBountyAmount
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose
    WHERE u.Reputation > 1000
    GROUP BY u.Id
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Comment,
        ph.CreationDate AS CloseDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) as CloseRnk
    FROM PostHistory ph
    WHERE ph.PostHistoryTypeId = 10 -- Post Closed
),
CombinedData AS (
    SELECT 
        rp.PostId,
        rp.Title,
        ua.DisplayName,
        ua.TotalViews,
        ua.PostedCount,
        ua.AvgBountyAmount,
        cp.CloseDate,
        cp.Comment
    FROM RankedPosts rp
    LEFT JOIN UserActivity ua ON rp.PostId = (
        SELECT Top(1) UserId FROM Users WHERE Id = rp.OwnerUserId
    )
    LEFT JOIN ClosedPosts cp ON rp.PostId = cp.PostId AND cp.CloseRnk = 1
    WHERE rp.Rnk <= 5
)
SELECT 
    cd.PostId,
    cd.Title,
    cd.DisplayName,
    cd.TotalViews,
    cd.PostedCount,
    cd.AvgBountyAmount,
    COALESCE(cd.CloseDate, 'Not Closed') AS CloseDate,
    COALESCE(cd.Comment, 'No comments') AS CloseComment
FROM CombinedData cd
ORDER BY cd.TotalViews DESC, cd.Score DESC
LIMIT 10;

-- Edge cases
-- 1. Using COALESCE to handle NULL values for closed posts
-- 2. Utilizing ROW_NUMBER for ranking posts by score and creation date
-- 3. Combining multiple CTEs to aggregate user activity and closed post information
-- 4. Handling interest by focusing on posts in the last year, with certain user reputation
