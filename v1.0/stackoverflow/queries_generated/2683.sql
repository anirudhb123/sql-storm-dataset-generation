WITH UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END), 0) AS AnswerCount,
        COALESCE(SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END), 0) AS QuestionCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpvoteCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownvoteCount
    FROM 
        Users u
    LEFT JOIN 
        Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        u.Id, u.DisplayName
), 
BadgeStatistics AS (
    SELECT 
        UserId,
        COUNT(*) AS TotalBadges,
        COUNT(CASE WHEN Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN Class = 3 THEN 1 END) AS BronzeBadges
    FROM 
        Badges
    GROUP BY 
        UserId
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM 
        Tags t
    JOIN 
        Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '>,<')::int[])
    GROUP BY 
        t.TagName
    HAVING 
        COUNT(p.Id) > 10
)

SELECT 
    ua.UserId,
    ua.DisplayName,
    ua.QuestionCount,
    ua.AnswerCount,
    ua.UpvoteCount,
    ua.DownvoteCount,
    COALESCE(b.TotalBadges, 0) AS TotalBadges,
    COALESCE(b.GoldBadges, 0) AS GoldBadges,
    COALESCE(b.SilverBadges, 0) AS SilverBadges,
    COALESCE(b.BronzeBadges, 0) AS BronzeBadges,
    (SELECT COUNT(*) FROM PopularTags WHERE PostCount > 5) AS PopularTagCount
FROM 
    UserActivity ua
LEFT JOIN 
    BadgeStatistics b ON ua.UserId = b.UserId
WHERE 
    ua.AnswerCount > 0
ORDER BY 
    OverallRank DESC, ua.UpvoteCount DESC
LIMIT 100;
