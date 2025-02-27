WITH TagCounts AS (
    SELECT 
        Tags.TagName, 
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.Score IS NOT NULL THEN 1 ELSE 0 END) AS ActivePosts,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN 1 ELSE 0 END) AS ClosedPosts
    FROM 
        Tags 
    LEFT JOIN 
        Posts p ON p.Tags LIKE '%' || Tags.TagName || '%' 
    LEFT JOIN 
        PostHistory ph ON ph.PostId = p.Id 
    GROUP BY 
        Tags.TagName
), 
UserActivity AS (
    SELECT 
        u.DisplayName, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(v.BountyAmount) AS AvgBountyAmount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN 
        Votes v ON v.UserId = u.Id
    LEFT JOIN 
        Badges b ON b.UserId = u.Id
    GROUP BY 
        u.DisplayName
)
SELECT 
    tc.TagName,
    tc.PostCount,
    tc.ActivePosts,
    tc.ClosedPosts,
    ua.DisplayName,
    ua.TotalPosts,
    ua.Questions,
    ua.Answers,
    ua.AvgBountyAmount,
    ua.GoldBadges,
    ua.SilverBadges,
    ua.BronzeBadges
FROM 
    TagCounts tc
JOIN 
    UserActivity ua ON ua.TotalPosts > 0
ORDER BY 
    tc.PostCount DESC, 
    ua.TotalPosts DESC
LIMIT 10;
