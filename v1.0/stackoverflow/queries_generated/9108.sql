WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(CASE WHEN p.Score IS NOT NULL THEN p.Score ELSE 0 END) AS AverageScore,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
TopActiveUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        Questions, 
        Answers, 
        AverageScore, 
        TotalViews, 
        GoldBadges, 
        SilverBadges, 
        BronzeBadges
    FROM 
        UserPostStats
    WHERE 
        TotalPosts > 0
    ORDER BY 
        TotalPosts DESC
    LIMIT 10
),
PostHistoryDetails AS (
    SELECT 
        ph.PostId,
        COUNT(*) AS EditCount,
        MAX(ph.CreationDate) AS LastEdited,
        STRING_AGG(DISTINCT pht.Name ORDER BY ph.CreationDate) AS EditTypes
    FROM 
        PostHistory ph
    JOIN 
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY 
        ph.PostId
)
SELECT 
    t.UserId,
    t.DisplayName,
    t.TotalPosts,
    t.Questions,
    t.Answers,
    t.AverageScore,
    t.TotalViews,
    t.GoldBadges,
    t.SilverBadges,
    t.BronzeBadges,
    phed.EditCount,
    phed.LastEdited,
    phed.EditTypes
FROM 
    TopActiveUsers t
LEFT JOIN 
    PostHistoryDetails phed ON t.UserId IN (SELECT OwnerUserId FROM Posts WHERE Id = phed.PostId)
ORDER BY 
    t.TotalPosts DESC;
