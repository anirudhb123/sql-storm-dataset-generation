
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        AVG(COALESCE(p.Score, 0)) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPosts AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.OwnerUserId,
        @row_number := IF(@prev_owner_user_id = p.OwnerUserId, @row_number + 1, 1) AS rn,
        @prev_owner_user_id := p.OwnerUserId
    FROM 
        Posts p
    CROSS JOIN (SELECT @row_number := 0, @prev_owner_user_id := NULL) AS vars
    WHERE 
        p.CreationDate > NOW() - INTERVAL 1 YEAR
    ORDER BY 
        p.OwnerUserId, p.CreationDate DESC
)
SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AvgScore,
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    CASE 
        WHEN rp.ViewCount IS NULL THEN 'No views'
        ELSE CONCAT(rp.ViewCount, ' views')
    END AS FormattedViewCount
FROM 
    UserPostStats ups
LEFT JOIN 
    RecentPosts rp ON ups.UserId = rp.OwnerUserId AND rp.rn = 1
WHERE 
    ups.TotalPosts > 0
ORDER BY 
    ups.AvgScore DESC
LIMIT 10;
