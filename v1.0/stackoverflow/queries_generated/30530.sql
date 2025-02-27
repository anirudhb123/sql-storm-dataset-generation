WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        Title,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.Title,
        p.ParentId,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.Score, 0)) AS TotalScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS rn
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 month'
),
PostsWithComments AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    GROUP BY 
        p.Id, p.Title
)
SELECT 
    u.UserId,
    u.DisplayName,
    ups.PostCount,
    ups.TotalScore,
    ups.TotalViews,
    pp.CommentCount,
    (SELECT STRING_AGG(DISTINCT rp.Title, '; ' ORDER BY rp.CreationDate DESC)
     FROM RecentPosts rp
     WHERE rp.OwnerUserId = u.UserId AND rp.rn <= 5) AS RecentPostTitles,
    (SELECT STRING_AGG(DISTINCT rph.Title, ', ' ORDER BY rph.Level)
     FROM RecursivePostHierarchy rph
     WHERE rph.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE OwnerUserId = u.UserId)
    ) AS AcceptedAnswerTitles
FROM 
    UserPostStats ups
JOIN 
    Users u ON ups.UserId = u.Id
LEFT JOIN 
    PostsWithComments pp ON pp.PostId IN (SELECT Id FROM Posts WHERE OwnerUserId = u.Id)
WHERE 
    u.Reputation > 1000 AND 
    u.LastAccessDate >= NOW() - INTERVAL '6 months'
ORDER BY 
    ups.TotalScore DESC
LIMIT 20;
