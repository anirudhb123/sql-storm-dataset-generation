WITH UserContribution AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COALESCE(SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,  -- answering questions
        COALESCE(SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,  -- asking questions
        COALESCE(SUM(CASE WHEN C.Id IS NOT NULL THEN 1 ELSE 0 END), 0) AS CommentCount
    FROM 
        Users U
    LEFT JOIN 
        Posts P ON U.Id = P.OwnerUserId
    LEFT JOIN 
        Comments C ON P.Id = C.PostId
    WHERE 
        U.CreationDate < NOW() - INTERVAL '1 year'  -- users active for more than a year
    GROUP BY 
        U.Id
),
UserBadges AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
RankedContributions AS (
    SELECT 
        uc.UserId,
        uc.DisplayName,
        uc.AnswerCount,
        uc.QuestionCount,
        ub.GoldBadges,
        ub.SilverBadges,
        ub.BronzeBadges,
        RANK() OVER (ORDER BY uc.AnswerCount DESC) AS ContributionRank
    FROM 
        UserContribution uc
    LEFT JOIN 
        UserBadges ub ON uc.UserId = ub.UserId
)
SELECT 
    DISTINCT
    rc.DisplayName,
    rc.AnswerCount,
    rc.QuestionCount,
    rc.GoldBadges,
    rc.SilverBadges,
    rc.BronzeBadges,
    CASE 
        WHEN rc.ContributionRank <= 10 THEN 'Top Contributor'
        ELSE 'Regular Contributor'
    END AS ContributorType,
    CASE 
        WHEN rc.GoldBadges IS NULL AND rc.SilverBadges IS NULL AND rc.BronzeBadges IS NULL THEN 'No Badges'
        ELSE 'Has Badges'
    END AS BadgeStatus
FROM 
    RankedContributions rc
WHERE 
    (rc.AnswerCount > 5 OR rc.QuestionCount > 3)  -- filter criteria
ORDER BY 
    rc.ContributionRank, rc.DisplayName;

-- A complex query that involves:
-- 1. CTEs for structured aggregation of user contributions and badges.
-- 2. Conditional aggregation and NULL handling with COALESCE.
-- 3. Window functions to rank users based on their contributions.
-- 4. Distinct selection with case statements for categorization of contributors.
