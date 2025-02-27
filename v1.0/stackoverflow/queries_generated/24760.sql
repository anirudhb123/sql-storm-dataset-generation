WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.Score,
        p.ViewCount,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS RankByScore,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.ViewCount DESC) AS RankByView
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= NOW() - INTERVAL '1 year' 
        AND p.Score > 0
),
TopPosts AS (
    SELECT 
        rp.Id,
        rp.Title,
        rp.Score,
        rp.ViewCount,
        CASE 
            WHEN rp.RankByScore <= 3 THEN 'Top Score'
            WHEN rp.RankByView <= 3 THEN 'Top Viewed'
            ELSE 'Regular'
        END AS PostCategory
    FROM 
        RankedPosts rp
    WHERE 
        rp.RankByScore <= 5 OR rp.RankByView <= 5
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId = 10 THEN ph.CreationDate END) AS ClosedDate,
        MAX(CASE WHEN ph.PostHistoryTypeId = 11 THEN ph.CreationDate END) AS ReopenedDate
    FROM 
        PostHistory ph
    GROUP BY 
        ph.PostId
)
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    ub.UserId,
    ub.BadgeCount,
    COALESCE(ph.ClosedDate, ph.ReopenedDate) AS StatusDate,
    CASE 
        WHEN ph.ClosedDate IS NOT NULL AND ph.ReopenedDate IS NULL THEN 'Closed'
        WHEN ph.ReopenedDate IS NOT NULL THEN 'Reopened'
        ELSE 'Active'
    END AS PostStatus,
    p.ViewCount,
    td.PostCategory
FROM 
    TopPosts p
LEFT JOIN 
    UserBadges ub ON p.OwnerUserId = ub.UserId
LEFT JOIN 
    PostHistoryDetails ph ON p.Id = ph.PostId
WHERE 
    ub.BadgeCount >= 3
ORDER BY 
    p.Score DESC, p.ViewCount DESC;

EXPLAIN ANALYZE
SELECT 
    COUNT(*) AS TotalPosts,
    AVG(Score) AS AverageScore,
    SUM(CASE WHEN PostCategory = 'Top Score' THEN 1 ELSE 0 END) AS TopScorePosts,
    SUM(CASE WHEN PostCategory = 'Top Viewed' THEN 1 ELSE 0 END) AS TopViewedPosts
FROM 
    TopPosts;

This SQL query includes complex constructs such as Common Table Expressions (CTEs) to rank posts, categorize them based on score and view count, and fetch associated user badge counts. It also considers the state of posts (whether they are closed or reopened) by looking at the PostHistory while applying aggregation functions to gather performance-related data. The use of correlated subqueries, combined with meticulous ordering and filtering, ensures that this query is both intricate and performant for benchmarking.
