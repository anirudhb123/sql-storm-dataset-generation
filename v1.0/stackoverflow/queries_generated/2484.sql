WITH RankedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        p.ViewCount,
        p.CreationDate,
        p.Score,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS Rank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
        AND p.Score IS NOT NULL 
        AND p.CreationDate >= NOW() - INTERVAL '1 year'
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalQuestions,
        SUM(CASE WHEN p.Score >= 0 THEN 1 ELSE 0 END) AS UpvotedQuestions,
        SUM(CASE WHEN p.Score < 0 THEN 1 ELSE 0 END) AS DownvotedQuestions
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY 
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 -- Gold badges
    GROUP BY 
        b.UserId
),
PostLinksSummary AS (
    SELECT 
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM 
        PostLinks pl
    GROUP BY 
        pl.PostId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.TotalQuestions,
    ua.UpvotedQuestions,
    ua.DownvotedQuestions,
    COALESCE(ub.BadgeCount, 0) AS GoldBadges,
    p.Title,
    p.ViewCount,
    g.Rank,
    pls.RelatedPostCount
FROM 
    UserActivity ua
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN 
    RankedPosts p ON p.OwnerUserId = ua.UserId 
LEFT JOIN 
    PostLinksSummary pls ON pls.PostId = p.Id 
LEFT JOIN 
    LATERAL (SELECT * FROM RankedPosts WHERE OwnerUserId = ua.UserId ORDER BY ViewCount DESC LIMIT 1) g ON g.Id = p.Id
ORDER BY 
    ua.TotalQuestions DESC, 
    g.ViewCount DESC
LIMIT 50;
