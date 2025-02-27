WITH RECURSIVE UserHierarchy AS (
    SELECT Id, DisplayName, Reputation, CreationDate, NULL AS ParentId
    FROM Users
    WHERE Reputation > (SELECT AVG(Reputation) FROM Users)
    
    UNION ALL
    
    SELECT u.Id, u.DisplayName, u.Reputation, u.CreationDate,
           uh.Id
    FROM Users u
    INNER JOIN UserHierarchy uh ON u.Reputation > uh.Reputation
    WHERE u.Id <> uh.Id
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 2) AS Upvotes,
        COUNT(DISTINCT v.Id) FILTER (WHERE v.VoteTypeId = 3) AS Downvotes,
        AVG(v.BountyAmount) FILTER (WHERE v.BountyAmount IS NOT NULL) AS AvgBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.OwnerUserId
),
UserPostSummary AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(ps.CommentCount), 0) AS TotalComments,
        COALESCE(SUM(ps.Upvotes), 0) AS TotalUpvotes,
        COALESCE(SUM(ps.Downvotes), 0) AS TotalDownvotes,
        COALESCE(SUM(ps.AvgBounty), 0) AS TotalBounty
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    uh.DisplayName AS UserName,
    uh.Reputation,
    up.TotalComments,
    up.TotalUpvotes,
    up.TotalDownvotes,
    up.TotalBounty
FROM 
    UserHierarchy uh
LEFT JOIN 
    UserPostSummary up ON uh.Id = up.UserId
ORDER BY 
    uh.Reputation DESC, up.TotalUpvotes DESC
LIMIT 50;
