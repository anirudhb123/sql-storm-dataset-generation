
WITH UserStats AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate, 
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        AVG(ISNULL(p.Score, 0)) AS AvgScore,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
PostHistoryCounts AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        SUM(CASE WHEN ph.PostHistoryTypeId IN (4, 5) THEN 1 ELSE 0 END) AS TitleBodyEdits
    FROM 
        PostHistory ph
    WHERE 
        ph.CreationDate >= DATEADD(YEAR, -1, '2024-10-01 12:34:56')
    GROUP BY 
        ph.UserId
)
SELECT 
    us.DisplayName, 
    us.Reputation, 
    us.TotalPosts, 
    us.TotalAnswers, 
    us.AvgScore,
    ISNULL(ph.EditCount, 0) AS TotalEdits,
    ISNULL(ph.TitleBodyEdits, 0) AS TotalTitleBodyEdits,
    'Gold: ' + CAST(us.GoldBadges AS VARCHAR) + ', Silver: ' + CAST(us.SilverBadges AS VARCHAR) + ', Bronze: ' + CAST(us.BronzeBadges AS VARCHAR) AS BadgeSummary
FROM 
    UserStats us
LEFT JOIN 
    PostHistoryCounts ph ON us.UserId = ph.UserId
WHERE 
    us.Reputation > 1000 AND 
    (us.TotalPosts > 50 OR us.TotalAnswers > 20)
ORDER BY 
    us.Reputation DESC
OFFSET 0 ROWS FETCH NEXT 10 ROWS ONLY;
