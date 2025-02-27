WITH RankedPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.AnswerCount,
        p.ViewCount,
        RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(MONTH, -12, GETDATE())
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
PostStatistics AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.Score >= 10 THEN 1 ELSE 0 END) AS HighScorePosts,
        AVG(p.ViewCount) AS AvgViewsPerPost
    FROM 
        Posts p
    WHERE 
        p.CreationDate >= DATEADD(YEAR, -1, GETDATE())
    GROUP BY 
        p.OwnerUserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    COALESCE(ps.TotalPosts, 0) AS TotalPosts,
    COALESCE(ps.HighScorePosts, 0) AS HighScorePosts,
    COALESCE(bs.BadgeCount, 0) AS BadgeCount,
    COALESCE(bs.GoldBadges, 0) AS GoldBadges,
    COALESCE(bs.SilverBadges, 0) AS SilverBadges,
    COALESCE(bs.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(avgScore, 0) AS AveragePostScore,
    COUNT(DISTINCT rp.PostId) AS HighRankedPosts
FROM 
    Users u
LEFT JOIN 
    PostStatistics ps ON u.Id = ps.OwnerUserId
LEFT JOIN 
    UserBadges bs ON u.Id = bs.UserId
LEFT JOIN 
    RankedPosts rp ON u.Id = rp.OwnerUserId AND rp.PostRank <= 10
LEFT JOIN (
    SELECT 
        OwnerUserId,
        AVG(Score) AS avgScore
    FROM 
        Posts
    WHERE 
        Score IS NOT NULL
    GROUP BY 
        OwnerUserId
) avgScores ON u.Id = avgScores.OwnerUserId
WHERE 
    u.Reputation > 50
GROUP BY 
    u.Id
ORDER BY 
    TotalPosts DESC, BadgeCount DESC;
