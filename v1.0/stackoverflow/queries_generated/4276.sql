WITH UserReputation AS (
    SELECT 
        u.Id AS UserId, 
        u.DisplayName, 
        u.Reputation, 
        u.CreationDate,
        RANK() OVER (ORDER BY u.Reputation DESC) AS ReputationRank
    FROM Users u 
    WHERE u.Reputation > 1000
),
PostActivity AS (
    SELECT 
        p.OwnerUserId,
        COUNT(p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        MAX(p.CreationDate) AS LastPostDate
    FROM Posts p 
    GROUP BY p.OwnerUserId
),
UserBadges AS (
    SELECT 
        b.UserId, 
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b 
    GROUP BY b.UserId
)
SELECT 
    ur.DisplayName, 
    ur.Reputation, 
    pa.PostCount,
    pa.QuestionCount, 
    pa.AnswerCount, 
    COALESCE(ub.GoldBadges, 0) AS GoldBadges, 
    COALESCE(ub.SilverBadges, 0) AS SilverBadges, 
    COALESCE(ub.BronzeBadges, 0) AS BronzeBadges, 
    DATEDIFF('day', ur.CreationDate, CURRENT_TIMESTAMP) AS AccountAge,
    CASE 
        WHEN ur.Reputation > 5000 THEN 'High Contributor' 
        WHEN ur.Reputation BETWEEN 1000 AND 5000 THEN 'Moderate Contributor' 
        ELSE 'New Contributor' 
    END AS ContributorLevel
FROM UserReputation ur
LEFT JOIN PostActivity pa ON ur.UserId = pa.OwnerUserId
LEFT JOIN UserBadges ub ON ur.UserId = ub.UserId
WHERE (pa.PostCount IS NULL OR pa.PostCount > 2)
    AND NOT EXISTS (
        SELECT 1 
        FROM Comments c 
        WHERE c.UserId = ur.UserId 
        AND c.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    )
ORDER BY ur.Reputation DESC, ur.DisplayName ASC
LIMIT 10;
