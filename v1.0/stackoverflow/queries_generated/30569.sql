WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS ScoreRank,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVoteCount,
        SUM(v.VoteTypeId = 3) AS DownVoteCount
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount
), 
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        MAX(b.Class) AS HighestBadgeClass
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.*,
        u.DisplayName AS OwnerDisplayName,
        COALESCE(CAST(NULLIF(b.BadgeCount, 0) AS VARCHAR), 'No Badges') AS UserBadges
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UsersWithBadges b ON u.Id = b.UserId
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '30 days'
)

SELECT 
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.Score,
    rp.ViewCount,
    rp.ScoreRank,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    r.OwnerDisplayName,
    r.UserBadges
FROM 
    RankedPosts rp
JOIN 
    RecentPosts r ON rp.PostId = r.Id
WHERE 
    rp.ScoreRank <= 10
ORDER BY 
    r.CreationDate DESC;

WITH RECURSIVE PostHierarchy AS (
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
        ph.Level + 1
    FROM 
        Posts p
    JOIN 
        PostHierarchy ph ON p.ParentId = ph.Id
)

SELECT 
    ph.Id AS PostId, 
    ph.Title, 
    ph.Level
FROM 
    PostHierarchy ph
WHERE 
    ph.Level > 2
ORDER BY 
    ph.Level DESC;

-- An aggregate of views and average scores for each post type
SELECT 
    pt.Name AS PostType,
    COUNT(p.Id) AS PostCount,
    SUM(p.ViewCount) AS TotalViews,
    AVG(p.Score) AS AverageScore
FROM 
    Posts p
JOIN 
    PostTypes pt ON p.PostTypeId = pt.Id
GROUP BY 
    pt.Id, pt.Name
HAVING 
    AVG(p.Score) > 0
ORDER BY 
    TotalViews DESC;
