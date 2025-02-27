WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.CreationDate,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN UNNEST(string_to_array(p.Tags, '><')) AS t(TagName) ON t.TagName IS NOT NULL
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.CreationDate
),
ActiveUser AS (
    SELECT 
        ua.*,
        RANK() OVER (ORDER BY ua.Reputation DESC) AS ReputationRank,
        ROW_NUMBER() OVER (PARTITION BY ua.Reputation ORDER BY ua.CreationDate) AS CreationRow
    FROM UserActivity ua
    WHERE ua.PostCount > 0
),
TopUsers AS (
    SELECT *
    FROM ActiveUser
    WHERE ReputationRank <= 10
    AND (CreationRow % 2 = 0)  -- just selecting users created on even rows for some odd reason
),
UserBadges AS (
    SELECT 
        b.UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
)
SELECT 
    u.DisplayName,
    u.Reputation,
    u.TotalViews,
    ub.BadgeCount,
    ub.GoldBadges,
    ub.SilverBadges,
    ub.BronzeBadges,
    CASE 
        WHEN u.QuestionCount > 0 THEN 'Active Questioner'
        WHEN u.AnswerCount > 0 THEN 'Active Responder'
        ELSE 'Inactive'
    END AS UserStatus,
    ARRAY_AGG(DISTINCT COALESCE(pt.Name, 'Unspecified')) AS PostTypes
FROM TopUsers u
LEFT JOIN UserBadges ub ON u.UserId = ub.UserId
LEFT JOIN Posts p ON u.UserId = p.OwnerUserId
LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id 
WHERE u.Tags IS NOT NULL
GROUP BY u.DisplayName, u.Reputation, u.TotalViews, ub.BadgeCount, ub.GoldBadges, ub.SilverBadges, ub.BronzeBadges
HAVING COUNT(p.Id) FILTER (WHERE p.Score > 10) > 1   -- Ensure top users have more than one well-received post
ORDER BY u.Reputation DESC, u.TotalViews DESC;
