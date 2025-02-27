WITH NotableUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(DISTINCT p.Id) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(b.Class = 1) AS GoldBadges,
        SUM(b.Class = 2) AS SilverBadges,
        SUM(b.Class = 3) AS BronzeBadges,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM 
        Users u
        LEFT JOIN Posts p ON u.Id = p.OwnerUserId
        LEFT JOIN Badges b ON u.Id = b.UserId
        LEFT JOIN STRING_SPLIT(p.Tags, '>') t ON 1=1 -- Using STRING_SPLIT to aggregate tags
    WHERE 
        u.Reputation >= 1000
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation
    HAVING 
        COUNT(DISTINCT p.Id) > 10
),

UserActivity AS (
    SELECT 
        u.DisplayName,
        COUNT(DISTINCT ph.Id) AS EditCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM 
        Users u
        JOIN PostHistory ph ON u.Id = ph.UserId
        LEFT JOIN Comments c ON ph.PostId = c.PostId
    GROUP BY 
        u.DisplayName
),

CombinedResults AS (
    SELECT 
        nu.UserId,
        nu.DisplayName,
        nu.Reputation,
        nu.PostCount,
        nu.AnswerCount,
        nu.QuestionCount,
        nu.GoldBadges,
        nu.SilverBadges,
        nu.BronzeBadges,
        nu.Tags,
        ua.EditCount,
        ua.CommentCount,
        ua.LastEditDate
    FROM 
        NotableUsers nu
        JOIN UserActivity ua ON nu.DisplayName = ua.DisplayName
)

SELECT 
    *,
    CASE 
        WHEN PostCount > 50 THEN 'High Contributor'
        WHEN PostCount BETWEEN 20 AND 50 THEN 'Moderate Contributor'
        ELSE 'Emerging Contributor'
    END AS ContributorLevel
FROM 
    CombinedResults
ORDER BY 
    Reputation DESC, PostCount DESC;
