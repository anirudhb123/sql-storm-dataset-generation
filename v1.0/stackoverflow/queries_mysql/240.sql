
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS Questions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS Answers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        (SELECT AVG(Reputation) FROM Users) AS AvgReputation
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
RecentPostHistory AS (
    SELECT 
        ph.PostId,
        ph.CreationDate,
        ph.PostHistoryTypeId,
        @rn := IF(@prev_post = ph.PostId, @rn + 1, 1) AS rn,
        @prev_post := ph.PostId,
        p.Title
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id,
        (SELECT @rn := 0, @prev_post := NULL) AS vars
    WHERE 
        ph.CreationDate >= NOW() - INTERVAL 30 DAY
    ORDER BY 
        ph.PostId, ph.CreationDate DESC
)
SELECT 
    ups.DisplayName,
    ups.TotalPosts,
    ups.Questions,
    ups.Answers,
    ups.AcceptedAnswers,
    ups.AvgReputation,
    COALESCE(rph.Title, 'No Recent Edits') AS RecentPostTitle,
    rph.CreationDate AS LastEditDate,
    CASE 
        WHEN ups.TotalPosts > 0 THEN 
            ROUND((CAST(ups.AcceptedAnswers AS DECIMAL) / NULLIF(ups.Questions, 0)) * 100, 2) 
        ELSE 
            0 
    END AS AcceptanceRate
FROM 
    UserPostStats ups
LEFT JOIN 
    RecentPostHistory rph ON ups.UserId = (SELECT OwnerUserId FROM Posts WHERE Id = rph.PostId AND rph.rn = 1)
WHERE 
    ups.AvgReputation > (SELECT AVG(Reputation) FROM Users)
ORDER BY 
    ups.TotalPosts DESC, ups.DisplayName;
