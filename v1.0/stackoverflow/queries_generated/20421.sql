WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Considering only Questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties,
        COALESCE(MAX(CASE WHEN v.VoteTypeId = 2 THEN v.CreationDate END), '1970-01-01') AS LastUpvoteDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.PostId = p.Id
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    ua.DisplayName,
    ua.TotalPosts,
    ua.TotalBounties,
    COUNT(ch.Comment) AS CommentCount,
    MAX(ch.CreationDate) AS LastCommentDate,
    (SELECT COUNT(1) FROM RankedPosts rp WHERE rp.OwnerUserId = ua.UserId AND rp.PostRank <= 3) AS RecentTopQuestions,
    CASE 
        WHEN ua.TotalBounties > 0 THEN 'Has Bounties'
        ELSE 'No Bounties'
    END AS BountyStatus,
    CASE 
        WHEN DATEDIFF(CURRENT_TIMESTAMP, LastUpvoteDate) < 30 THEN 'Active User'
        ELSE 'Inactive User'
    END AS UserActivityStatus
FROM 
    UserActivity ua
LEFT JOIN 
    Comments ch ON ch.UserId = ua.UserId
GROUP BY 
    ua.DisplayName, ua.TotalPosts, ua.TotalBounties
HAVING 
    COUNT(DISTINCT ch.Id) > 5 -- Only users with more than 5 comments
ORDER BY 
    ua.TotalPosts DESC, ua.TotalBounties DESC;

WITH BountyDetails AS (
    SELECT 
        v.PostId,
        SUM(v.BountyAmount) AS TotalBountyAmount,
        COUNT(v.Id) AS TotalBountyVotes
    FROM 
        Votes v
    WHERE 
        v.VoteTypeId IN (8, 9) -- BountyStart and BountyClose
    GROUP BY 
        v.PostId
)
SELECT 
    p.Title,
    p.ViewCount,
    COALESCE(b.TotalBountyAmount, 0) AS TotalBounties,
    COALESCE(b.TotalBountyVotes, 0) AS TotalVotes,
    CASE 
        WHEN b.TotalBountyVotes IS NULL OR b.TotalBountyVotes = 0 THEN 'No Bounty Activity'
        ELSE 'Bounty Activity Present'
    END AS BountyActivity,
    (SELECT COUNT(1) FROM Comments c WHERE c.PostId = p.Id) AS TotalComments
FROM 
    Posts p
LEFT JOIN 
    BountyDetails b ON b.PostId = p.Id
WHERE 
    COALESCE(b.TotalBountyVotes, 0) > 0 
    OR p.ViewCount > 1000 -- High visibility Post
ORDER BY 
    p.CreationDate DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY; -- Top 5 recent posts with bounty activity or high visibility
