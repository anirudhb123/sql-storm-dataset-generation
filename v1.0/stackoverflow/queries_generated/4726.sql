WITH UserPostStats AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        COUNT(p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        SUM(CASE WHEN p.PostTypeId = 1 AND p.AcceptedAnswerId IS NOT NULL THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    GROUP BY 
        u.Id, u.Reputation
),
TopUsers AS (
    SELECT 
        UserId,
        Reputation,
        TotalPosts,
        TotalAnswers,
        AcceptedAnswers,
        RANK() OVER (ORDER BY Reputation DESC) AS ReputationRank
    FROM 
        UserPostStats
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    u.UserId,
    u.Reputation,
    u.TotalPosts,
    u.TotalAnswers,
    u.AcceptedAnswers,
    ub.BadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames,
    CASE 
        WHEN u.AcceptedAnswers > 0 THEN 'Yes'
        ELSE 'No'
    END AS HasAcceptedAnswers
FROM 
    TopUsers u
LEFT JOIN 
    UserBadges ub ON u.UserId = ub.UserId
WHERE 
    u.ReputationRank <= 10
ORDER BY 
    u.Reputation DESC;

-- Additional Analysis: Determine influence based on questions answered and view count
WITH QuestionStats AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS QuestionCount,
        SUM(p.ViewCount) AS TotalViews
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1
    GROUP BY 
        p.OwnerUserId
),
InfluentialUsers AS (
    SELECT 
        us.UserId,
        us.Reputation,
        qs.QuestionCount,
        qs.TotalViews,
        (us.TotalAnswers::float / NULLIF(qs.QuestionCount, 0)) * 100 AS AnswerPercentage
    FROM 
        TopUsers us
    JOIN 
        QuestionStats qs ON us.UserId = qs.OwnerUserId
    WHERE 
        us.TotalAnswers > 0
)
SELECT 
    iu.UserId,
    iu.Reputation,
    iu.QuestionCount,
    iu.TotalViews,
    ROUND(iu.AnswerPercentage, 2) AS AnswerPercentage
FROM 
    InfluentialUsers iu
WHERE 
    iu.AnswerPercentage > 50
ORDER BY 
    iu.Reputation DESC;
