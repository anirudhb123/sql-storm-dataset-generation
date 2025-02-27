WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS UserPostRank
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId 
    WHERE 
        p.PostTypeId = 1 -- Questions only
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) FILTER (WHERE b.Class = 1) AS GoldBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 2) AS SilverBadges,
        COUNT(b.Id) FILTER (WHERE b.Class = 3) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
AggregatedData AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(rb.GoldBadges, 0) AS GoldBadges,
        COALESCE(rb.SilverBadges, 0) AS SilverBadges,
        COALESCE(rb.BronzeBadges, 0) AS BronzeBadges,
        SUM(rp.ViewCount) AS TotalViews,
        SUM(rp.Score) AS TotalScore,
        COUNT(DISTINCT rp.PostId) AS TotalQuestions,
        AVG(rp.CommentCount) AS AvgCommentsPerQuestion
    FROM 
        Users u
    LEFT JOIN 
        UserBadges rb ON u.Id = rb.UserId
    LEFT JOIN 
        RankedPosts rp ON u.Id = rp.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    a.UserId,
    a.DisplayName,
    a.GoldBadges,
    a.SilverBadges,
    a.BronzeBadges,
    a.TotalViews,
    a.TotalScore,
    a.TotalQuestions,
    a.AvgCommentsPerQuestion,
    CASE 
        WHEN a.TotalScore < 10 THEN 'Low Engagement'
        WHEN a.TotalScore BETWEEN 10 AND 50 THEN 'Moderate Engagement'
        ELSE 'High Engagement' 
    END AS EngagementLevel
FROM 
    AggregatedData a
WHERE 
    a.TotalQuestions > 5
ORDER BY 
    a.TotalScore DESC
OFFSET 10 LIMIT 10;

-- Check for NULL logic
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(a.TotalViews, 0) AS TotalViews,
    COALESCE(a.AvgCommentsPerQuestion, 0) AS AvgComments
FROM 
    Users u
LEFT JOIN (
    SELECT 
        rp.OwnerUserId,
        SUM(rp.ViewCount) AS TotalViews,
        AVG(rp.CommentCount) AS AvgCommentsPerQuestion
    FROM 
        RankedPosts rp
    GROUP BY 
        rp.OwnerUserId
) a ON u.Id = a.OwnerUserId
WHERE 
    u.Location IS NOT NULL;
