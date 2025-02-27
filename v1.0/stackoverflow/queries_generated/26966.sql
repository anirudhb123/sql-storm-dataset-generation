WITH UserTagCounts AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.ID) AS PostsCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount,
        STRING_AGG(DISTINCT SUBSTRING(t.TagName, 1, 20), ', ') AS TopTags
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        LATERAL (
            SELECT 
                unnest(string_to_array(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '>')) AS TagName
        ) t ON TRUE
    GROUP BY 
        u.Id
), 
UserBadges AS (
    SELECT 
        UserId,
        COUNT(Id) AS BadgeCount,
        STRING_AGG(Name, ', ') AS BadgeNames
    FROM 
        Badges
    GROUP BY 
        UserId
), 
UserProfiles AS (
    SELECT 
        u.Id AS UserId,
        u.Reputation,
        u.Location,
        ub.BadgeCount,
        ub.BadgeNames,
        utc.PostsCount,
        utc.QuestionsCount,
        utc.AnswersCount,
        utc.TopTags
    FROM 
        Users u
    LEFT JOIN 
        UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN 
        UserTagCounts utc ON u.Id = utc.UserId
    WHERE 
        u.Reputation > 1000
)
SELECT 
    UserId,
    DisplayName,
    Reputation,
    Location,
    BadgeCount,
    BadgeNames,
    PostsCount,
    QuestionsCount,
    AnswersCount,
    TopTags
FROM 
    UserProfiles
WHERE 
    BadgeCount > 5 OR QuestionsCount > 10
ORDER BY 
    Reputation DESC, 
    PostsCount DESC;
