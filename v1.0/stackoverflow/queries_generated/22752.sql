WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId IN (1, 2) THEN p.Score ELSE 0 END), 0) AS TotalScore,
        ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) DESC) AS Rank
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
),
PostHistoryStats AS (
    SELECT 
        ph.UserId,
        COUNT(*) AS EditCount,
        MIN(ph.CreationDate) AS FirstEditDate,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId IN (4, 5, 6) -- Editing events
    GROUP BY 
        ph.UserId
),
FilteredBadges AS (
    SELECT 
        b.UserId,
        b.Name,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM 
        Badges b
    WHERE 
        b.Class = 1 OR b.Class = 2 -- Only Gold or Silver badges
    GROUP BY 
        b.UserId, b.Name, b.Class
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    us.QuestionCount,
    us.AnswerCount,
    us.TotalScore,
    COALESCE(phs.EditCount, 0) AS EditCount,
    phs.FirstEditDate,
    phs.LastEditDate,
    COUNT(fb.BadgeCount) AS BadgeCount,
    STRING_AGG(DISTINCT CONCAT_WS(' - ', fb.Class, fb.Name), ', ') AS BadgeNames,
    CASE 
        WHEN MAX(ph.CreateDate) IS NULL THEN 'Never edited'
        ELSE 'Has edited'
    END AS EditStatus,
    CASE 
        WHEN us.TotalScore >= 1000 THEN 'Highly Active'
        WHEN us.TotalScore > 0 THEN 'Moderately Active'
        ELSE 'Inactive'
    END AS ActivityLevel
FROM 
    Users u
LEFT JOIN 
    UserPostStats us ON u.Id = us.UserId
LEFT JOIN 
    PostHistoryStats phs ON u.Id = phs.UserId
LEFT JOIN 
    FilteredBadges fb ON u.Id = fb.UserId
LEFT JOIN 
    Posts p ON u.Id = p.OwnerUserId
GROUP BY 
    u.Id, u.DisplayName, us.QuestionCount, us.AnswerCount, us.TotalScore, phs.EditCount, 
    phs.FirstEditDate, phs.LastEditDate
HAVING 
    COALESCE(us.QuestionCount, 0) > 0 OR COALESCE(phs.EditCount, 0) > 0
ORDER BY 
    us.QuestionCount DESC, us.TotalScore DESC;
