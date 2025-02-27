WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties,
        AVG(COALESCE(Score, 0)) AS AvgPostScore,
        SUM(COALESCE(CASE WHEN c.UserId IS NOT NULL THEN 1 ELSE 0 END, 0)) AS TotalComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id, u.DisplayName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalBounties,
        AvgPostScore,
        TotalComments,
        ROW_NUMBER() OVER (ORDER BY TotalBounties DESC, AvgPostScore DESC) AS Rank
    FROM 
        UserActivity
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.TotalPosts,
    u.TotalBounties,
    u.AvgPostScore,
    u.TotalComments,
    COALESCE(pH.Depth, 0) AS MaxPostDepth,
    CASE 
        WHEN u.TotalPosts > 0 THEN 'Active User' 
        ELSE 'Inactive User' 
    END AS UserStatus
FROM 
    TopUsers u
LEFT JOIN (
    SELECT 
        ph.Id,
        MAX(ph.Level) AS Depth
    FROM 
        RecursivePostHierarchy ph
    GROUP BY 
        ph.Id
) pH ON u.UserId = pH.Id
WHERE 
    u.Rank <= 10 -- limiting the results to top 10 users
ORDER BY 
    u.TotalBounties DESC, 
    u.AvgPostScore DESC;
