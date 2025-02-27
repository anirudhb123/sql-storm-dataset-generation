WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId, 
        Title, 
        ParentId, 
        OwnerUserId, 
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL
    
    UNION ALL
    
    SELECT 
        p.Id, 
        p.Title, 
        p.ParentId, 
        p.OwnerUserId, 
        h.Level + 1 AS Level
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy h ON p.ParentId = h.PostId
),
UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AverageViewCount,
        MIN(p.CreationDate) AS FirstPostDate,
        MAX(p.CreationDate) AS LastPostDate
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    GROUP BY 
        u.Id, u.DisplayName
),
TopVotedPosts AS (
    SELECT 
        Id, 
        Title, 
        Score, 
        OwnerUserId,
        ROW_NUMBER() OVER (PARTITION BY OwnerUserId ORDER BY Score DESC) AS Rank
    FROM 
        Posts
    WHERE 
        Score > 0
),
RelatedPostLinks AS (
    SELECT 
        pl.PostId, 
        COUNT(pl.RelatedPostId) AS RelatedCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)

SELECT 
    u.DisplayName AS Author,
    COUNT(p.Id) AS TotalPostsMade,
    COALESCE(SUM(rv.Score), 0) AS TotalReceivedVotes,
    SUM(COALESCE(r.RelatedCount, 0)) AS TotalRelatedLinks,
    MAX(d.FirstPostDate) AS FirstPostDate,
    MAX(d.LastPostDate) AS LastPostDate,
    CASE 
        WHEN AVG(d.AverageViewCount) IS NULL THEN 'No views'
        WHEN AVG(d.AverageViewCount) < 10 THEN 'Low visibility'
        WHEN AVG(d.AverageViewCount) BETWEEN 10 AND 100 THEN 'Moderate visibility'
        ELSE 'High visibility'
    END AS VisibilityCategory,
    COUNT(DISTINCT CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.Comment END) AS TotalPostsClosed
FROM 
    UserPostStats d
JOIN 
    Users u ON d.UserId = u.Id
LEFT JOIN 
    Posts p ON p.OwnerUserId = u.Id
LEFT JOIN 
    Votes rv ON rv.PostId = p.Id
LEFT JOIN 
    RelatedPostLinks r ON r.PostId = p.Id
LEFT JOIN 
    PostHistory ph ON ph.UserId = u.Id
GROUP BY 
    u.DisplayName
ORDER BY 
    TotalReceivedVotes DESC,
    TotalPostsMade DESC;
