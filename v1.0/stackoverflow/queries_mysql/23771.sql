
WITH UserBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(CASE WHEN b.Class = 1 THEN b.Id END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN b.Id END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN b.Id END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePosts,
        ROUND(SUM(p.Score) / NULLIF(COUNT(p.Score), 0), 0) AS MedianScore, -- Using approximation for Median in MySQL
        MAX(p.ViewCount) AS MaxViews,
        MIN(p.ViewCount) AS MinViews
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPostReasons AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalClosed,
        GROUP_CONCAT(DISTINCT crt.Name ORDER BY crt.Name SEPARATOR ', ') AS CloseReasons
    FROM 
        PostHistory ph
    JOIN 
        CloseReasonTypes crt ON CAST(ph.Comment AS UNSIGNED) = crt.Id
    WHERE 
        ph.PostHistoryTypeId IN (10, 11) 
    GROUP BY 
        ph.UserId
),
AggregatedStats AS (
    SELECT 
        ub.UserId,
        ub.DisplayName,
        COALESCE(ps.TotalPosts, 0) AS TotalPosts,
        COALESCE(ps.PositivePosts, 0) AS PositivePosts,
        COALESCE(ps.MedianScore, 0) AS MedianScore,
        COALESCE(ps.MaxViews, 0) AS MaxViews,
        COALESCE(ps.MinViews, 0) AS MinViews,
        COALESCE(cb.TotalClosed, 0) AS TotalClosed,
        COALESCE(cb.CloseReasons, 'No reasons') AS CloseReasons,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges
    FROM 
        UserBadgeStats ub
    LEFT JOIN 
        PostStats ps ON ub.UserId = ps.OwnerUserId
    LEFT JOIN 
        ClosedPostReasons cb ON ub.UserId = cb.UserId
)
SELECT 
    UserId,
    DisplayName,
    TotalPosts,
    PositivePosts,
    MedianScore,
    MaxViews,
    MinViews,
    TotalClosed,
    CloseReasons,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    CONCAT('Total Posts: ', TotalPosts, 
           '; Positive Posts: ', PositivePosts, 
           '; Median Score: ', MedianScore) AS SummaryStats
FROM 
    AggregatedStats
WHERE 
    (GoldBadges > 0 OR SilverBadges > 0 OR BronzeBadges > 0)
ORDER BY 
    TotalPosts DESC, PositivePosts DESC;
