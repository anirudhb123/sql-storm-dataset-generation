WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.OwnerUserId, 
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
        p.OwnerUserId,
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p 
    INNER JOIN 
        RecursivePostHierarchy rp ON p.ParentId = rp.PostId
),
UserBadges AS (
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
        u.Id
),
PostStatistics AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(p.Score, 0) AS Score,
        COALESCE(p.AnswerCount, 0) AS AnswerCount,
        COALESCE(p.ViewCount, 0) AS ViewCount,
        u.DisplayName AS OwnerDisplayName,
        ub.BadgeCount,
        ub.HighestBadgeClass
    FROM 
        Posts p
    LEFT JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
),
FilteredPosts AS (
    SELECT 
        ps.PostId,
        ps.Title,
        ps.CreationDate,
        ps.Score,
        ps.AnswerCount,
        ps.ViewCount,
        ps.OwnerDisplayName,
        ps.BadgeCount,
        ps.HighestBadgeClass,
        RANK() OVER (PARTITION BY ps.OwnerDisplayName ORDER BY ps.CreationDate DESC) AS OwnerPostRank
    FROM 
        PostStatistics ps
    WHERE 
        ps.Score > 10 AND 
        ps.AnswerCount > 0
)
SELECT 
    f.OwnerDisplayName,
    COUNT(f.PostId) AS TotalPosts,
    SUM(f.ViewCount) AS TotalViews,
    MAX(f.BadgeCount) AS MaxBadges,
    AVG(f.Score) AS AverageScore,
    STRING_AGG(DISTINCT f.Title, ', ') AS PostTitles
FROM 
    FilteredPosts f
GROUP BY 
    f.OwnerDisplayName
HAVING 
    COUNT(f.PostId) > 5
ORDER BY 
    TotalViews DESC;
