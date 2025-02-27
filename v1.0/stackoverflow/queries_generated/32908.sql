WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        ParentId,
        Title,
        OwnerUserId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id,
        p.ParentId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(c.Id, 0)) AS TotalComments,
        RANK() OVER (ORDER BY SUM(COALESCE(p.ViewCount, 0)) DESC) AS ViewRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        u.Id
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalViews,
        TotalPosts,
        TotalComments
    FROM 
        UserActivity
    WHERE 
        ViewRank <= 10 
),
PostStats AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS CommentCount,
        SUM(v.BountyAmount) AS TotalBounty,
        COUNT(DISTINCT v.Id) AS VoteCount,
        AVG(v.BountyAmount) AS AverageBounty
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate,
        COUNT(ph.Id) AS CloseReasonCount
    FROM 
        Posts p
    JOIN 
        PostHistory ph ON p.Id = ph.PostId 
    WHERE 
        ph.PostHistoryTypeId = 10 
    GROUP BY 
        p.Id, p.Title, ph.CreationDate
),
FinalReport AS (
    SELECT 
        p.Title,
        p.CommentCount,
        ps.TotalBounty,
        ps.VoteCount,
        cp.CloseReasonCount,
        tu.DisplayName AS TopUser
    FROM 
        PostStats ps
    LEFT JOIN
        ClosedPosts cp ON ps.PostId = cp.Id
    LEFT JOIN 
        Posts p ON ps.PostId = p.Id
    CROSS JOIN 
        TopUsers tu
    ORDER BY 
        ps.TotalBounty DESC
)
SELECT 
    *,
    CASE 
        WHEN CloseReasonCount > 0 THEN 'Closed'
        ELSE 'Open'
    END AS PostStatus
FROM 
    FinalReport;
