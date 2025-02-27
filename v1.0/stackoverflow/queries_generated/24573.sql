WITH UserBadgeCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users u
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id, u.DisplayName
),
QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(*) AS QuestionCount,
        SUM(CASE WHEN p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswerCount,
        AVG(p.Score) AS AvgScore
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 
          AND p.CreationDate >= NOW() - INTERVAL '1 year' -- Questions created in the last year
    GROUP BY 
        p.OwnerUserId
),
PostActivity AS (
    SELECT 
        ph.PostId,
        ph.UserId,
        ph.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY ph.PostId ORDER BY ph.CreationDate DESC) AS ActivityOrder
    FROM 
        PostHistory ph
    WHERE 
        ph.PostHistoryTypeId = 24 -- Suggested Edit Applied
),
RecentActivity AS (
    SELECT 
        p.Id AS PostId,
        COALESCE(pa.UserId, -1) AS LastActivityUser, -- -1 if no activity
        MAX(pa.CreationDate) AS LastActivityDate
    FROM 
        Posts p
    LEFT JOIN 
        PostActivity pa ON p.Id = pa.PostId
    GROUP BY 
        p.Id
)
SELECT 
    u.Id AS UserId,
    u.DisplayName,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    qs.QuestionCount,
    qs.AcceptedAnswerCount,
    qs.AvgScore,
    ra.PostId,
    ra.LastActivityUser,
    ra.LastActivityDate
FROM 
    Users u
LEFT JOIN 
    UserBadgeCounts ub ON u.Id = ub.UserId
LEFT JOIN 
    QuestionStats qs ON u.Id = qs.OwnerUserId
LEFT JOIN 
    RecentActivity ra ON u.Id = ra.LastActivityUser
WHERE 
    (ub.BadgeCount IS NULL OR ub.BadgeCount > 0) 
    AND (qs.QuestionCount IS NULL OR qs.QuestionCount > 5) -- Users with more than 5 questions
    AND (ra.LastActivityDate IS NOT NULL OR ra.LastActivityUser = -1) -- Users with activity or no activity
ORDER BY 
    ub.BadgeCount DESC, 
    qs.QuestionCount DESC, 
    qs.AvgScore DESC
FETCH FIRST 100 ROWS ONLY;
This SQL query performs various operations:
1. It begins with Common Table Expressions (CTEs) to calculate user badge counts, statistics for users who asked questions, the activities associated with posts, and the most recent activity of users.
2. It aggregates user data and filters them based on badge counts and questions asked.
3. It incorporates complex logic using NULL checks and aggregates.
4. The final result includes user identifiers, their display names, their badge counts, as well as statistics regarding questions they've asked or related activities.
