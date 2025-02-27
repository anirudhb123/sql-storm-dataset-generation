WITH UserTags AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        t.TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        Users u
    JOIN 
        Posts p ON u.Id = p.OwnerUserId
    CROSS JOIN 
        LATERAL unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS t(TagName)
    GROUP BY 
        u.Id, u.DisplayName, t.TagName
),
TopUsers AS (
    SELECT 
        UserId,
        DisplayName,
        SUM(TagUsageCount) AS TotalTags
    FROM 
        UserTags
    GROUP BY 
        UserId, DisplayName
    ORDER BY 
        TotalTags DESC
    LIMIT 10
),
UserBadges AS (
    SELECT 
        ub.UserId,
        COUNT(*) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM 
        Badges ub
    JOIN 
        Users u ON ub.UserId = u.Id
    GROUP BY 
        ub.UserId
)
SELECT 
    tu.DisplayName,
    tu.TotalTags,
    COALESCE(ub.BadgeCount, 0) AS BadgeCount,
    COALESCE(ub.BadgeNames, 'No Badges') AS BadgeNames
FROM 
    TopUsers tu
LEFT JOIN 
    UserBadges ub ON tu.UserId = ub.UserId
ORDER BY 
    tu.TotalTags DESC;

This query performs several operations to benchmark string processing by exploring user contributions and badge counts within the Stack Overflow schema. It counts the number of tag usages per user, retrieves the top 10 users based on total tag usages, and then joins this information with the badges earned by those users. The output includes the user's display name, total tag visibility, number of badges, and the names of those badges, providing a comprehensive view of user engagement through tag usage and badge accumulation.
