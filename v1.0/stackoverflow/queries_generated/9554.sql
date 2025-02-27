WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    WHERE 
        u.CreationDate < NOW() - INTERVAL '1 year' 
    GROUP BY 
        u.Id, u.DisplayName
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(ph.Id) AS TotalEdits,
        COUNT(DISTINCT ph.PostId) AS UniquePostsEdited
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate > NOW() - INTERVAL '6 months'
    GROUP BY 
        ph.UserId
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.TotalQuestions,
    ups.TotalAnswers,
    ups.TotalScore,
    ups.AvgViews,
    ups.GoldBadges,
    ups.SilverBadges,
    ups.BronzeBadges,
    COALESCE(phs.TotalEdits, 0) AS TotalEdits,
    COALESCE(phs.UniquePostsEdited, 0) AS UniquePostsEdited
FROM 
    UserPostStats ups
LEFT JOIN 
    PostHistoryStats phs ON ups.UserId = phs.UserId
ORDER BY 
    ups.TotalScore DESC, ups.TotalPosts DESC
LIMIT 100;
