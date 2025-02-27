WITH RecentUserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsAsked,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersGiven,
        SUM(v.BountyAmount) AS TotalBountyReceived,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY u.LastAccessDate DESC) AS ActivityRank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    WHERE 
        u.CreationDate > NOW() - INTERVAL '1 year'
    GROUP BY 
        u.Id, u.DisplayName
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS PostsCreated,
        AVG(p.ViewCount) AS AvgViewCount,
        SUM(CASE WHEN p.Score IS NULL THEN 0 ELSE p.Score END) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
ClosedPosts AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS ClosedPostCount,
        SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS TotalClosed,
        SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS TotalReopened
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.PostCount,
    ua.QuestionsAsked,
    ua.AnswersGiven,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    COALESCE(ps.PostsCreated, 0) AS PostsCreated,
    COALESCE(ps.AvgViewCount, 0) AS AvgViewCount,
    COALESCE(ps.TotalScore, 0) AS TotalScore,
    COALESCE(cp.ClosedPostCount, 0) AS ClosedPosts,
    COALESCE(cp.TotalClosed, 0) AS TotalClosed,
    COALESCE(cp.TotalReopened, 0) AS TotalReopened
FROM 
    RecentUserActivity ua
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN 
    PostStats ps ON ua.UserId = ps.OwnerUserId
LEFT JOIN 
    ClosedPosts cp ON ua.UserId = cp.UserId
WHERE 
    ua.ActivityRank <= 10
ORDER BY 
    ua.PostCount DESC, ua.DisplayName;
