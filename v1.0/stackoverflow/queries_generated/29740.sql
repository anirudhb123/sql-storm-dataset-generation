WITH TagStatistics AS (
    SELECT 
        T.TagName,
        COUNT(P.Id) AS PostCount,
        SUM(CASE WHEN P.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionCount,
        SUM(CASE WHEN P.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswerCount,
        AVG(U.Reputation) AS AvgUserReputation
    FROM 
        Tags T
        LEFT JOIN Posts P ON P.Tags LIKE CONCAT('%<', T.TagName, '>%')
        LEFT JOIN Users U ON P.OwnerUserId = U.Id
    GROUP BY 
        T.TagName
),
UserBadgeStatistics AS (
    SELECT 
        U.Id AS UserId,
        U.DisplayName,
        COUNT(B.Id) AS BadgeCount,
        AVG(CASE WHEN B.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        AVG(CASE WHEN B.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        AVG(CASE WHEN B.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM 
        Users U
        LEFT JOIN Badges B ON U.Id = B.UserId
    GROUP BY 
        U.Id, U.DisplayName
),
CombinedStatistics AS (
    SELECT 
        TS.TagName,
        TS.PostCount,
        TS.QuestionCount,
        TS.AnswerCount,
        UDS.DisplayName,
        UDS.BadgeCount,
        UDS.GoldBadges,
        UDS.SilverBadges,
        UDS.BronzeBadges,
        TS.AvgUserReputation
    FROM 
        TagStatistics TS
        LEFT JOIN UserBadgeStatistics UDS ON UDS.BadgeCount > 0 -- Joining users with at least one badge
    ORDER BY 
        TS.PostCount DESC,
        UDS.BadgeCount DESC
)
SELECT 
    TagName,
    PostCount,
    QuestionCount,
    AnswerCount,
    DisplayName,
    BadgeCount,
    GoldBadges,
    SilverBadges,
    BronzeBadges,
    AvgUserReputation
FROM 
    CombinedStatistics
WHERE 
    PostCount > 10 -- Filtering tags with more than 10 posts
ORDER BY 
    AvgUserReputation DESC,
    PostCount DESC;
This query benchmark not only handles string processing via the manipulation of tags from the `Tags` table, but also aggregates user statistics from the `Users` table based on their associated badges from the `Badges` table. The result joins statistical data for tags with user contributions and reputation, sorted by various criteria, making it suitable for benchmarking performance in string-related processing while demonstrating complex joins and aggregations.
