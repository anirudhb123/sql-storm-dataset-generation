WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ViewCount,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year'
), 
UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        ARRAY_AGG(DISTINCT b.Name) AS BadgeArray
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8 -- BountyStart
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
), 
CloseReasons AS (
    SELECT 
        ph.PostId,
        STRING_AGG(cr.Name || ': ' || ph.Comment) AS CloseDetails
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes cr ON ph.Comment::int = cr.Id
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId
), 
UserPostStats AS (
    SELECT 
        us.UserId,
        us.TotalPosts,
        us.TotalBounties,
        us.Reputation,
        COALESCE(cr.CloseDetails, 'No close reasons') AS CloseDetails
    FROM 
        UserStatistics us
    LEFT JOIN 
        CloseReasons cr ON us.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = cr.PostId)
)

SELECT 
    up.UserId,
    u.DisplayName,
    RANK() OVER (ORDER BY up.TotalBounties DESC, up.Reputation DESC) AS UserRank,
    up.TotalPosts,
    up.TotalBounties,
    up.CloseDetails,
    rp.Title,
    rp.ViewCount,
    CASE
        WHEN rp.Rank = 1 THEN 'Top Post'
        ELSE 'Other Post'
    END AS PostCategory
FROM 
    UserPostStats up
JOIN 
    Users u ON up.UserId = u.Id
JOIN 
    RankedPosts rp ON up.TotalPosts > 0
WHERE 
    up.Reputation BETWEEN 100 AND 1000
    AND up.TotalBounties IS NOT NULL
ORDER BY 
    UserRank, up.TotalBounties DESC, up.TotalPosts DESC;

-- Notes:
-- This query combines several advanced SQL constructs: CTEs, window functions, 
-- correlated subqueries, and joins. We rank posts by their score while also 
-- gathering statistics on users. Additionally, it includes information on closed 
-- posts and uses STRING_AGG to concatenate close reasons for posts.
-- The final SELECT also classifies the posts based on their rank within the respective 
-- category (top post vs other posts).
