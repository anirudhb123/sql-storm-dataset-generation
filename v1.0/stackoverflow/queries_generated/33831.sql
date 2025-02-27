WITH RECURSIVE RecentPosts AS (
    -- Select recent posts along with their respective details and rank
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.CreationDate DESC) AS PostRank,
        p.OwnerUserId,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3), 0) AS Score -- Calculating net score (upvotes - downvotes)
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.OwnerUserId, u.DisplayName
), TopUsers AS (
    -- Find top users based on their reputation
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        RANK() OVER (ORDER BY u.Reputation DESC) AS UserRank
    FROM 
        Users u
    WHERE 
        u.Reputation > 1000  -- Only consider users with reputation greater than 1000
), ClosedPosts AS (
    -- Get posts that have been closed along with the close reason type
    SELECT 
        p.Id AS PostId,
        p.Title,
        ph.CreationDate AS ClosureDate,
        c.Name AS CloseReason
    FROM 
        Posts p 
    JOIN 
        PostHistory ph ON p.Id = ph.PostId AND ph.PostHistoryTypeId = 10
    JOIN 
        CloseReasonTypes c ON ph.Comment::int = c.Id
), PostStatistics AS (
    -- Aggregate statistics for each post type
    SELECT 
        pt.Name AS PostTypeName,
        COUNT(p.Id) AS TotalPosts,
        AVG(p.ViewCount) AS AvgViews
    FROM 
        Posts p
    JOIN 
        PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        pt.Name
)
SELECT 
    rp.Title,
    rp.PostId,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    tu.DisplayName AS TopUser,
    tu.Reputation,
    cp.ClosureDate,
    cp.CloseReason,
    ps.TotalPosts,
    ps.AvgViews
FROM 
    RecentPosts rp
FULL OUTER JOIN 
    TopUsers tu ON rp.OwnerUserId = tu.UserId
LEFT JOIN 
    ClosedPosts cp ON rp.PostId = cp.PostId
JOIN 
    PostStatistics ps ON TRUE -- Joining to get stats for all post types
WHERE 
    rp.PostRank <= 5 -- Limit the results to top 5 recent posts per post type
ORDER BY 
    rp.CreationDate DESC,
    rp.Score DESC;
