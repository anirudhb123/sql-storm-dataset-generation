WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    GROUP BY u.Id
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS TotalQuestions,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedQuestions,
        AVG(p.Score) AS AvgQuestionScore
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.OwnerUserId
),
UserActivity AS (
    SELECT 
        ua.UserId,
        SUM(uc.Views) AS TotalViews,
        SUM(uc.UpVotes) AS TotalUpVotes,
        SUM(uc.DownVotes) AS TotalDownVotes,
        ROW_NUMBER() OVER (PARTITION BY ua.UserId ORDER BY SUM(uc.Views) DESC) AS ActivityRank
    FROM Users ua
    LEFT JOIN Posts p ON ua.Id = p.OwnerUserId
    LEFT JOIN Comments uc ON p.Id = uc.PostId
    GROUP BY ua.UserId
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    qs.TotalQuestions,
    qs.AcceptedQuestions,
    qs.AvgQuestionScore,
    ua.TotalViews,
    ua.TotalUpVotes,
    ua.TotalDownVotes,
    COALESCE(ua.ActivityRank, 0) AS ActivityRank
FROM Users u
LEFT JOIN UserBadges ub ON u.Id = ub.UserId
LEFT JOIN QuestionStats qs ON u.Id = qs.OwnerUserId
LEFT JOIN UserActivity ua ON u.Id = ua.UserId
WHERE (ub.BadgeCount > 0 OR qs.TotalQuestions > 0 OR ua.TotalViews > 0)
ORDER BY u.Reputation DESC, ua.TotalViews DESC NULLS LAST
LIMIT 50;
