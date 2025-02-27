WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS RecentPostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Only questions
),
PostStatistics AS (
    SELECT 
        up.UserId,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(p.Score) AS TotalScore,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Users up
    LEFT JOIN 
        Posts p ON up.Id = p.OwnerUserId AND p.PostTypeId = 1 -- Join to posts for questions
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        up.UserId
),
ClosedPosts AS (
    SELECT 
        p.Id AS ClosedPostId,
        p.Title,
        ph.UserId AS ClosedByUserId,
        ph.CreationDate AS ClosedDate,
        ph.Comment AS CloseReason
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
)
SELECT 
    u.DisplayName,
    r.TotalQuestions,
    r.TotalComments,
    r.TotalScore,
    r.TotalViews,
    COALESCE(cp.ClosedPostId, -1) AS ClosedPostId,
    COALESCE(cp.CloseReason, 'Not Closed') AS CloseReason,
    RANK() OVER (ORDER BY r.TotalScore DESC) AS UserRank,
    SUM(CASE WHEN r.RecentPostRank = 1 THEN 1 ELSE 0 END) OVER (PARTITION BY u.Id) AS MostRecentPost
FROM 
    Users u
JOIN 
    PostStatistics r ON u.Id = r.UserId
LEFT JOIN 
    ClosedPosts cp ON u.Id = cp.ClosedByUserId
WHERE 
    r.TotalQuestions > 0 OR r.TotalComments > 0
ORDER BY 
    u.Reputation DESC, UserRank;
