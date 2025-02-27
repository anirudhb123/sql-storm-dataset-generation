WITH AnswerStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalAnswers,
        AVG(p.Score) AS AvgAnswerScore,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 2 -- Answers
    GROUP BY 
        p.OwnerUserId
),
UserBadges AS (
    SELECT 
        u.Id AS UserId,
        STRING_AGG(b.Name, ', ') AS BadgeNames,
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
RankedUsers AS (
    SELECT 
        u.Id,
        u.DisplayName,
        us.TotalAnswers,
        us.AvgAnswerScore,
        us.AcceptedAnswers,
        us.TotalViews,
        ub.BadgeNames,
        RANK() OVER (ORDER BY us.TotalAnswers DESC, us.AvgAnswerScore DESC) AS UserRank
    FROM 
        Users u
    LEFT JOIN 
        AnswerStats us ON u.Id = us.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    WHERE 
        u.Reputation > 1000 -- Filtering for reputed users
)

SELECT 
    r.UserId,
    r.DisplayName,
    r.TotalAnswers,
    r.AcceptedAnswers,
    r.AvgAnswerScore,
    r.TotalViews,
    COALESCE(r.BadgeNames, 'No badges') AS BadgeNames,
    CASE 
        WHEN r.UserRank <= 10 THEN 'Top Contributor'
        WHEN r.UserRank BETWEEN 11 AND 50 THEN 'Promising Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorLevel,
    COUNT(c.Id) AS TotalComments
FROM 
    RankedUsers r
LEFT JOIN 
    Comments c ON c.UserId = r.UserId
GROUP BY 
    r.UserId, r.DisplayName, r.TotalAnswers, r.AcceptedAnswers, r.AvgAnswerScore, r.TotalViews, r.BadgeNames, r.UserRank
ORDER BY 
    r.UserRank
FETCH FIRST 20 ROWS ONLY;

-- Checking for inactive users versus active users
WITH InactiveUsers AS (
    SELECT 
        Id, 
        DisplayName, 
        DATEDIFF(CURRENT_TIMESTAMP, LastAccessDate) AS DaysInactive 
    FROM 
        Users 
    WHERE 
        LastAccessDate < CURRENT_DATE - INTERVAL '1 year'
), 
UserActivity AS (
    SELECT 
        u.Id, 
        SUM(CASE WHEN p.CreationDate >= CURRENT_DATE - INTERVAL '1 year' THEN 1 ELSE 0 END) AS RecentPosts,
        SUM(CASE WHEN c.CreationDate >= CURRENT_DATE - INTERVAL '1 year' THEN 1 ELSE 0 END) AS RecentComments
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    GROUP BY 
        u.Id
)

SELECT 
    u.Id,
    u.DisplayName,
    CASE 
        WHEN u.Id IN (SELECT Id FROM InactiveUsers) THEN 'Inactive' 
        ELSE 'Active' 
    END AS UserStatus,
    ua.RecentPosts,
    ua.RecentComments
FROM 
    Users u
LEFT JOIN 
    UserActivity ua ON u.Id = ua.Id
ORDER BY 
    UserStatus DESC, 
    u.DisplayName;
