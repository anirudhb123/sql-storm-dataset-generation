WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Start with questions
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT v.Id) AS TotalVotes,
        COUNT(DISTINCT b.Id) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.Reputation > 100  -- Only consider users with reputation > 100
    GROUP BY 
        u.Id, u.DisplayName
),
PostScoreCalculations AS (
    SELECT 
        p.Id AS PostId,
        p.Score,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounty
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- Bounty close votes
    GROUP BY 
        p.Id, p.Score
),
ClosedPosts AS (
    SELECT 
        ph.PostId,
        ph.Title,
        COUNT(ph.Id) AS CloseActions,
        MAX(p.Score) AS MaxScore,
        SUM(ps.TotalBounty) AS TotalBounty
    FROM 
        PostHistory ph
    INNER JOIN 
        Posts p ON ph.PostId = p.Id
    INNER JOIN 
        PostScoreCalculations ps ON p.Id = ps.PostId
    WHERE 
        ph.PostHistoryTypeId = 10 -- Post Closed
    GROUP BY 
        ph.PostId, ph.Title
)
SELECT 
    u.UserId,
    u.DisplayName,
    ua.TotalPosts,
    ua.TotalComments,
    ua.TotalVotes,
    ua.TotalBadges,
    cp.Title,
    cp.CloseActions,
    cp.MaxScore,
    cp.TotalBounty,
    ROW_NUMBER() OVER (PARTITION BY cp.CloseActions ORDER BY ua.TotalPosts DESC) AS UserRank
FROM 
    UserActivity ua
INNER JOIN 
    ClosedPosts cp ON ua.UserId IN (SELECT DISTINCT UserId FROM Posts p WHERE p.OwnerUserId IS NOT NULL)
ORDER BY 
    cp.CloseActions DESC, 
    ua.TotalPosts DESC;
