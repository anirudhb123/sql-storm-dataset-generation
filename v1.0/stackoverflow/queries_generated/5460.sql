WITH TagCounts AS (
    SELECT 
        Tags.TagName, 
        COUNT(Posts.Id) AS PostCount,
        SUM(CASE WHEN Posts.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN Posts.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount
    FROM 
        Tags
    LEFT JOIN 
        Posts ON Tags.Id = ANY(string_to_array(substring(Posts.Tags, 2, length(Posts.Tags)-2), '><')::int[])
    GROUP BY 
        Tags.TagName
), UserReputation AS (
    SELECT 
        Users.Id AS UserId, 
        Users.DisplayName,
        SUM(CASE WHEN Posts.OwnerUserId IS NOT NULL THEN 1 ELSE 0 END) AS PostCount,
        SUM(Users.Reputation) AS TotalReputation
    FROM 
        Users
    LEFT JOIN 
        Posts ON Users.Id = Posts.OwnerUserId
    GROUP BY 
        Users.Id, Users.DisplayName
), TopBadges AS (
    SELECT 
        Badges.UserId, 
        COUNT(Badges.Id) AS BadgeCount
    FROM 
        Badges
    GROUP BY 
        Badges.UserId
), RankedUsers AS (
    SELECT 
        UR.UserId, 
        UR.DisplayName, 
        UR.PostCount, 
        UR.TotalReputation,
        COALESCE(TB.BadgeCount, 0) AS BadgeCount,
        RANK() OVER (ORDER BY UR.TotalReputation DESC, UR.PostCount DESC) AS UserRank
    FROM 
        UserReputation UR
    LEFT JOIN 
        TopBadges TB ON UR.UserId = TB.UserId
)
SELECT 
    TC.TagName,
    RU.DisplayName,
    RU.PostCount,
    RU.TotalReputation,
    RU.BadgeCount
FROM 
    TagCounts TC
JOIN 
    Posts P ON TC.TagName = ANY(string_to_array(substring(P.Tags, 2, length(P.Tags)-2), '><'))
JOIN 
    RankedUsers RU ON P.OwnerUserId = RU.UserId
WHERE 
    RU.UserRank <= 10
ORDER BY 
    TC.PostCount DESC, RU.TotalReputation DESC;
