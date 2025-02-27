WITH TagPostCounts AS (
    SELECT 
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '> <')) AS Tag,
        COUNT(Id) AS PostCount
    FROM 
        Posts 
    WHERE 
        PostTypeId = 1
    GROUP BY 
        Tag
),
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS QuestionCount,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 WHEN v.VoteTypeId = 3 THEN -1 ELSE 0 END) AS ReputationChange
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId AND p.PostTypeId = 1
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    GROUP BY 
        u.Id, u.DisplayName
)
SELECT 
    t.Tag,
    p.PostCount,
    u.UserId,
    u.DisplayName,
    u.QuestionCount,
    u.GoldBadges,
    u.SilverBadges,
    u.BronzeBadges,
    u.ReputationChange
FROM 
    TagPostCounts t
JOIN 
    Users u ON u.Reputation > (
        SELECT COUNT(*) FROM Votes WHERE VoteTypeId = 2
    )
JOIN 
    UserActivity ua ON 1 = 1
JOIN 
    LATERAL (
        SELECT 
            COUNT(*) AS PostCount
        FROM 
            Posts 
        WHERE 
            Tags ILIKE '%' || t.Tag || '%'
    ) p ON p.PostCount > 0
ORDER BY 
    p.PostCount DESC, 
    u.ReputationChange DESC;
