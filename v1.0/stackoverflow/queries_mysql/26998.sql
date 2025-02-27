
WITH UserBadges AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        GROUP_CONCAT(b.Name SEPARATOR ', ') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
PostStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(p.ViewCount) AS TotalViews,
        SUM(p.Score) AS TotalScore
    FROM 
        Posts p
    GROUP BY 
        p.OwnerUserId
),
UserPostBadgeStats AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(ps.PostCount, 0) AS PostCount,
        COALESCE(ps.QuestionCount, 0) AS QuestionCount,
        COALESCE(ps.AnswerCount, 0) AS AnswerCount,
        COALESCE(ps.TotalViews, 0) AS TotalViews,
        COALESCE(ps.TotalScore, 0) AS TotalScore,
        COALESCE(ub.BadgeCount, 0) AS BadgeCount,
        COALESCE(ub.Badges, 'No Badges') AS Badges
    FROM 
        Users u
    LEFT JOIN 
        PostStats ps ON u.Id = ps.OwnerUserId
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
),
RankedUserStats AS (
    SELECT 
        *,
        @rank := IF(@prev_total_score = TotalScore AND @prev_total_views = TotalViews AND @prev_badge_count = BadgeCount, @rank, @rank + 1) AS Rank,
        @prev_total_score := TotalScore,
        @prev_total_views := TotalViews,
        @prev_badge_count := BadgeCount
    FROM 
        UserPostBadgeStats, (SELECT @rank := 0, @prev_total_score := NULL, @prev_total_views := NULL, @prev_badge_count := NULL) AS vars
    ORDER BY TotalScore DESC, TotalViews DESC, BadgeCount DESC
)
SELECT 
    Rank,
    UserId,
    DisplayName,
    PostCount,
    QuestionCount,
    AnswerCount,
    TotalViews,
    TotalScore,
    BadgeCount,
    Badges
FROM 
    RankedUserStats
WHERE 
    Rank <= 10
ORDER BY 
    Rank;
