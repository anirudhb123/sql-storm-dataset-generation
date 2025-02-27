WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        CAST(p.Title AS VARCHAR(MAX)) AS FullHierarchy,
        1 AS Depth
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        CAST(r.FullHierarchy + ' -> ' + p.Title AS VARCHAR(MAX)),
        r.Depth + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserReputationSummaries AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounty,
        SUM(COALESCE(b.Class, 0)) AS TotalBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId AND v.VoteTypeId = 8  -- Count only bounty start votes
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostActivityStatistics AS (
    SELECT 
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        SUM(COALESCE(v.VoteTypeId IS NOT NULL, 0)::int) AS VoteCount,
        MAX(p.CreationDate) AS LastActivityDate,
        AVG(p.Score) AS AverageScore
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.DisplayName,
    u.TotalPosts,
    u.TotalBounty,
    u.TotalBadges,
    p.PostId,
    p.CommentCount,
    p.VoteCount,
    p.LastActivityDate,
    p.AverageScore,
    r.FullHierarchy
FROM 
    UserReputationSummaries u
JOIN 
    Posts pr ON u.UserId = pr.OwnerUserId
LEFT JOIN 
    PostActivityStatistics p ON pr.Id = p.PostId
LEFT JOIN 
    RecursivePostHierarchy r ON pr.Id = r.PostId
WHERE 
    u.TotalBounty > 0
ORDER BY 
    u.TotalPosts DESC, u.TotalBounty DESC, p.AverageScore DESC
OFFSET 0 ROWS FETCH NEXT 25 ROWS ONLY;
