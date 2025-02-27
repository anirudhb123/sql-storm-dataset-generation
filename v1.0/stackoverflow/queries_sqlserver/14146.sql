
WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.Score) AS TotalScore,
        AVG(p.ViewCount) AS AvgViews,
        MAX(p.LastActivityDate) AS LastActivity
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.DisplayName
),
BadgeStats AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount,
        SUM(CASE WHEN Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
)

SELECT 
    ups.UserId,
    ups.DisplayName,
    ups.PostCount,
    ups.QuestionCount,
    ups.AnswerCount,
    ups.TotalScore,
    ups.AvgViews,
    ups.LastActivity,
    ISNULL(bs.BadgeCount, 0) AS BadgeCount,
    ISNULL(bs.GoldBadges, 0) AS GoldBadges,
    ISNULL(bs.SilverBadges, 0) AS SilverBadges,
    ISNULL(bs.BronzeBadges, 0) AS BronzeBadges
FROM 
    UserPostStats ups
LEFT JOIN 
    BadgeStats bs ON ups.UserId = bs.UserId
ORDER BY 
    ups.TotalScore DESC;
