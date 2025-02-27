WITH RankedPostScores AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.Score,
        p.CreationDate,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.Score DESC) AS ScoreRank
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionsAsked,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositiveQuestions,
        AVG(p.Score) AS AvgScore
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    GROUP BY
        u.Id, u.DisplayName
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,        -- Gold badges
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,     -- Silver badges
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges      -- Bronze badges
    FROM 
        Badges b
    GROUP BY 
        b.UserId
)
SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionsAsked,
    ua.PositiveQuestions,
    COALESCE(ub.GoldBadges, 0) AS GoldBadges,
    COALESCE(ub.SilverBadges, 0) AS SilverBadges,
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
    Coalesce(AVG(rp.Score), 0) AS AvgPostScore  -- Average score of posts for users with questions
FROM 
    UserActivity ua
LEFT JOIN 
    UserBadges ub ON ua.UserId = ub.UserId
LEFT JOIN 
    RankedPostScores rp ON ua.UserId = rp.OwnerUserId AND rp.ScoreRank = 1  -- Join on best score
GROUP BY 
    ua.UserId, ua.DisplayName, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
ORDER BY 
    ua.PositiveQuestions DESC, ua.QuestionsAsked DESC;

This query leverages Common Table Expressions (CTEs) to capture and compute user statistics from the Posts and Badges tables, integrating ranking for users' highest-scoring posts. It provides insights into user activity on the platform while also tallying the number of badges earned by each user. The final result is ordered based on user productivity (positive-scoring questions and total questions asked), showing how badges relate to user contributions and engagement in the Stack Overflow community.
