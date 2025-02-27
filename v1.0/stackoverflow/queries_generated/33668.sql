WITH RecursiveUserPosts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName, 
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(p.Views) AS TotalViews
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id
), 
TopUsers AS (
    SELECT 
        UserId, 
        DisplayName, 
        TotalPosts, 
        TotalQuestions, 
        TotalAnswers, 
        TotalViews,
        RANK() OVER (ORDER BY TotalPosts DESC) AS PostRank
    FROM 
        RecursiveUserPosts
), 
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS TotalBadges,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
),
PostHistoryRecords AS (
    SELECT 
        p.Id AS PostId,
        ph.UserId,
        ph.CreationDate,
        ph.Comment,
        ph.PostHistoryTypeId,
        (SELECT Name FROM PostHistoryTypes WHERE Id = ph.PostHistoryTypeId) AS HistoryType
    FROM 
        PostHistory ph
    JOIN 
        Posts p ON ph.PostId = p.Id
    WHERE 
        ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '30 days'
)
SELECT 
    u.DisplayName AS UserName,
    u.Reputation,
    t.TotalPosts,
    t.TotalQuestions,
    t.TotalAnswers,
    t.TotalViews,
    COALESCE(b.TotalBadges, 0) AS TotalBadges,
    COALESCE(b.BadgeNames, '') AS BadgeNames,
    COUNT(ph.PostId) AS RecentPostEdits,
    SUM(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 ELSE 0 END) AS CloseActions,
    SUM(CASE WHEN ph.PostHistoryTypeId = 11 THEN 1 ELSE 0 END) AS ReopenActions
FROM 
    Users u
JOIN 
    TopUsers t ON u.Id = t.UserId
LEFT JOIN 
    UserBadges b ON u.Id = b.UserId
LEFT JOIN 
    PostHistoryRecords ph ON u.Id = ph.UserId
WHERE 
    u.Reputation > (
        SELECT AVG(Reputation) FROM Users WHERE Reputation IS NOT NULL
    )
GROUP BY 
    u.Id, t.TotalPosts, t.TotalQuestions, t.TotalAnswers, t.TotalViews, b.TotalBadges, b.BadgeNames
ORDER BY 
    t.TotalPosts DESC, u.DisplayName
LIMIT 50;
