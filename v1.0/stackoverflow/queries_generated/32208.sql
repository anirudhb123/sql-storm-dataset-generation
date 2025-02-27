WITH RecursivePostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        1 as Level
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (10, 11)  -- Focus on closes and reopens only

    UNION ALL
    
    SELECT 
        p.ParentId,
        ph.CreationDate,
        ph.UserId,
        ph.Comment,
        Level + 1
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) AND 
        p.ParentId IS NOT NULL
),

ActiveUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        COUNT(DISTINCT p.Id) AS PostsCount,
        COUNT(DISTINCT ph.Id) AS ClosedPostsCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId IN (8, 9)  -- Bounty starts and closes
    LEFT JOIN 
        RecursivePostHistory rph ON p.Id = rph.PostId
    GROUP BY 
        u.Id
    HAVING 
        COUNT(DISTINCT rph.PostId) > 0  -- Only users with closed or reopened posts
),

TopActiveUsers AS (
    SELECT 
        *,
        RANK() OVER (ORDER BY TotalBounties DESC, PostsCount DESC) AS Ranking
    FROM 
        ActiveUsers
)

SELECT 
    u.Id,
    u.DisplayName,
    u.TotalBounties,
    u.PostsCount,
    u.ClosedPostsCount,
    u.Ranking,
    COALESCE(AVG(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END), 0) AS AvgClosureTime,
    STRING_AGG(DISTINCT p.Tags, ', ') AS PostTags
FROM 
    TopActiveUsers u
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
LEFT JOIN 
    PostHistory ph ON p.Id = ph.PostId
GROUP BY 
    u.Id, u.DisplayName, u.TotalBounties, u.PostsCount, u.ClosedPostsCount, u.Ranking
ORDER BY 
    u.Ranking
LIMIT 10;

This SQL query is designed to benchmark how active users engage with posts and how they influence post closures and bounties on a Stack Overflow-like database schema. It involves recursive common table expressions (CTEs) to traverse the history of post closures and reopens, aggregates user contributions through posts and bounties, and applies ranking and aggregate functions to display a comprehensive view of top active users.
