WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS LatestPostRank
    FROM 
        Posts p
    WHERE 
        p.Score IS NOT NULL AND 
        p.ViewCount > 1000
),

PostCloseReasons AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        pr.Name AS CloseReason,
        ph.CreationDate AS CloseDate
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes pr ON ph.Comment::int = pr.Id
    WHERE 
        ph.PostHistoryTypeId = 10
),

UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
)

SELECT 
    u.DisplayName,
    p.Title,
    p.CreationDate,
    p.Score,
    rb.GoldBadges,
    rb.SilverBadges,
    rb.BronzeBadges,
    pc.CloseReason,
    pc.CloseDate
FROM 
    RankedPosts p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UserBadgeStats rb ON u.Id = rb.UserId
LEFT JOIN 
    PostCloseReasons pc ON p.PostId = pc.PostId
WHERE 
    p.LatestPostRank = 1 -- Only the latest post per user
    AND (pc.CloseReason IS NULL OR pc.CloseDate >= NOW() - INTERVAL '1 year')
ORDER BY 
    p.Score DESC NULLS LAST
LIMIT 100;

This SQL query retrieves a list of users along with their latest posts that have high view counts and associated statistics regarding their badges. It also checks if the posts have been closed, providing relevant close reasons while incorporating various SQL constructs such as Common Table Expressions (CTEs), window functions for ranking, left joins, and complicated predicates for filtering based on the latest post and close date criteria. The inclusion of NULL logic in the WHERE clause caters to cases with no close reasons, ensuring they are retained in the output. The use of complex aggregations and derived calculations makes this query suitable for performance benchmarking.
