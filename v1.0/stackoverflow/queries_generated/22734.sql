WITH UserBadgeCounts AS (
    SELECT 
        UserId,
        COUNT(*) AS BadgeCount,
        SUM(CASE 
                WHEN Class = 1 THEN 1 
                ELSE 0 
            END) AS GoldBadgeCount,
        SUM(CASE 
                WHEN Class = 2 THEN 1 
                ELSE 0 
            END) AS SilverBadgeCount,
        SUM(CASE 
                WHEN Class = 3 THEN 1 
                ELSE 0 
            END) AS BronzeBadgeCount
    FROM 
        Badges
    GROUP BY 
        UserId
),
ActiveUsers AS (
    SELECT 
        Id,
        DisplayName,
        Reputation,
        Location,
        LastAccessDate,
        (SELECT COUNT(*) FROM Posts WHERE OwnerUserId = Users.Id AND PostTypeId = 1) AS QuestionCount
    FROM 
        Users
    WHERE 
        LastAccessDate > NOW() - INTERVAL '90 days'
),
PopularTags AS (
    SELECT 
        Tags.TagName,
        COUNT(*) AS TagUsageCount,
        ROW_NUMBER() OVER (ORDER BY COUNT(*) DESC) AS TagRank
    FROM 
        Posts
    CROSS JOIN LATERAL 
        unnest(string_to_array(Tags, '|')) AS Tag
    GROUP BY 
        TagName
    HAVING 
        COUNT(*) > 10
    ORDER BY 
        TagUsageCount DESC
),
UserActivity AS (
    SELECT 
        Users.Id AS UserId,
        Users.DisplayName,
        COALESCE(BadgeCounts.BadgeCount, 0) AS TotalBadges,
        COALESCE(SUM(Votes.VoteTypeId = 2), 0) AS UpvotesReceived,
        COALESCE(SUM(Comments.Id), 0) AS CommentsCount, 
        ARRAY_AGG(DISTINCT Tags.TagName) AS AssociatedTags
    FROM 
        Users
    LEFT JOIN UserBadgeCounts BadgeCounts ON Users.Id = BadgeCounts.UserId
    LEFT JOIN Posts ON Users.Id = Posts.OwnerUserId
    LEFT JOIN Votes ON Votes.UserId = Users.Id
    LEFT JOIN Comments ON Comments.UserId = Users.Id
    LEFT JOIN unnest(Posts.Tags) AS Tag ON True
    LEFT JOIN Tags ON Tag = Tags.TagName
    WHERE 
        Users.Reputation > 1000
    GROUP BY 
        Users.Id, Users.DisplayName
),
AggregatedResults AS (
    SELECT 
        ua.*,
        ARRAY_AGG(DISTINCT pt.Name) AS PostTypes,
        (SELECT COUNT(*) FROM UserActivity WHERE UserId = ua.UserId) AS ActivityCount
    FROM 
        UserActivity ua
    LEFT JOIN Posts p ON p.OwnerUserId = ua.UserId
    LEFT JOIN PostTypes pt ON p.PostTypeId = pt.Id
    GROUP BY 
        ua.UserId
)
SELECT 
    ar.DisplayName,
    ar.TotalBadges,
    ar.UpvotesReceived,
    ar.CommentsCount,
    COALESCE(pt.TagUsageCount, 0) AS PopularTagCount,
    ar.ActivityCount,
    CASE 
        WHEN ar.TotalBadges > 10 THEN 'Veteran'
        ELSE 'Novice'
    END AS UserCategory
FROM 
    AggregatedResults ar
LEFT JOIN (
    SELECT 
        TagName,
        COUNT(*) AS TagUsageCount
    FROM 
        PopularTags
    GROUP BY 
        TagName
) pt ON pt.TagName = ANY(ar.AssociatedTags)
WHERE 
    ar.ActivityCount > 5
ORDER BY 
    ar.UpvotesReceived DESC, ar.DisplayName;
