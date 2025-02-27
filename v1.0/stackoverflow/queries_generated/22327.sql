WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        MAX(v.VoteTypeId) AS LastVoteType
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
), 
UsersWithBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        MAX(u.Reputation) AS MaxReputation
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
TopPosts AS (
    SELECT 
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.CommentCount,
        uwb.BadgeCount,
        uwb.MaxReputation,
        CASE 
            WHEN uwb.BadgeCount > 0 THEN 'Yes'
            ELSE 'No' 
        END AS HasBadges
    FROM 
        RankedPosts rp
    INNER JOIN 
        UsersWithBadges uwb ON rp.OwnerUserId = uwb.UserId
    WHERE 
        rp.ViewCount > 100
)
SELECT 
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.CommentCount,
    tp.BadgeCount,
    tp.MaxReputation,
    tp.HasBadges
FROM 
    TopPosts tp
WHERE 
    tp.CommentCount = (SELECT MAX(CommentCount) FROM TopPosts)
    OR (tp.Score > 10 AND tp.HasBadges = 'Yes')
ORDER BY 
    tp.ViewCount DESC
LIMIT 10;

-- Extra Queries for Performance and Edge Cases

-- Query for finding orphaned posts (posts not having any comments or votes).
SELECT 
    p.Id AS OrphanedPostId,
    p.Title
FROM 
    Posts p
LEFT JOIN 
    Comments c ON p.Id = c.PostId
LEFT JOIN 
    Votes v ON p.Id = v.PostId
WHERE 
    c.Id IS NULL AND v.Id IS NULL;

-- Query to fetch posts with closed reason types and their respective history.
SELECT 
    ph.PostId,
    ph.CreationDate,
    ctr.Name AS CloseReasonName,
    COUNT(ph.Id) AS HistoryCount
FROM 
    PostHistory ph
JOIN 
    CloseReasonTypes ctr ON ph.Comment::int = ctr.Id -- considering PostHistoryTypeId = 10
WHERE 
    ph.PostHistoryTypeId = 10
GROUP BY 
    ph.PostId, ctr.Name, ph.CreationDate
HAVING 
    COUNT(ph.Id) > 1
ORDER BY 
    HistoryCount DESC;

-- An interesting examination of NULL logic and aggregate functions.
WITH UserStatistics AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(p.ViewCount), 0) AS TotalViews,
        COALESCE(COUNT(DISTINCT p.Id), 0) AS PostCount,
        COALESCE(SUM(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END), 0) AS TotalScore,
        CASE 
            WHEN COUNT(DISTINCT p.Id) > 0 THEN SUM(p.ViewCount) / COUNT(DISTINCT p.Id)
            ELSE NULL 
        END AS AvgViewsPerPost
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
)
SELECT 
    UserId,
    TotalViews,
    PostCount,
    TotalScore,
    AvgViewsPerPost
FROM 
    UserStatistics
WHERE 
    TotalViews IS NOT NULL AND AvgViewsPerPost IS NOT NULL
ORDER BY 
    TotalScore DESC
LIMIT 5;
