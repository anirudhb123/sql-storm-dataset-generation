WITH UserBadges AS (
    SELECT
        b.UserId,
        COUNT(CASE WHEN b.Class = 1 THEN 1 END) AS GoldBadges,
        COUNT(CASE WHEN b.Class = 2 THEN 1 END) AS SilverBadges,
        COUNT(CASE WHEN b.Class = 3 THEN 1 END) AS BronzeBadges
    FROM Badges b
    GROUP BY b.UserId
),
TopPostUsers AS (
    SELECT
        p.OwnerUserId,
        COUNT(*) AS PostCount,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS QuestionsCount,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS AnswersCount
    FROM Posts p
    WHERE p.CreationDate >= NOW() - INTERVAL '1 year'
    GROUP BY p.OwnerUserId
),
ActiveUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        COALESCE(ub.GoldBadges, 0) AS GoldBadges,
        COALESCE(ub.SilverBadges, 0) AS SilverBadges,
        COALESCE(ub.BronzeBadges, 0) AS BronzeBadges,
        COALESCE(tp.PostCount, 0) AS PostsInLastYear,
        COALESCE(tp.QuestionsCount, 0) AS QuestionsInLastYear,
        COALESCE(tp.AnswersCount, 0) AS AnswersInLastYear
    FROM Users u
    LEFT JOIN UserBadges ub ON u.Id = ub.UserId
    LEFT JOIN TopPostUsers tp ON u.Id = tp.OwnerUserId
    WHERE u.Reputation IS NOT NULL AND u.Reputation > 100
)
SELECT
    au.DisplayName,
    au.Reputation,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    au.PostsInLastYear,
    au.QuestionsInLastYear,
    au.AnswersInLastYear,
    CASE 
        WHEN au.GoldBadges > 5 THEN 'Gold Star'
        ELSE 'Regular User'
    END AS UserCategory,
    (SELECT 
        STRING_AGG(DISTINCT t.TagName, ', ') 
     FROM Posts p 
     JOIN Tags t ON t.Id = ANY(string_to_array(p.Tags, ', ')) 
     WHERE p.OwnerUserId = au.Id) AS MostUsedTags
FROM ActiveUsers au
ORDER BY au.Reputation DESC, au.PostsInLastYear DESC
LIMIT 10;

This SQL query consists of several CTEs that allow us to analyze users based on their badges and posts made over the last year, incorporating various SQL features such as:

- **Common Table Expressions (CTEs)**: Used to aggregate badge counts and post counts for users.
- **LEFT JOINs**: To ensure users with no badges or posts are still included in the final results.
- **COALESCE**: To handle NULL values, ensuring users with no badges or posts still receive a count of zero.
- **Subquery**: To aggregate the most used tags by each user from their posts.
- **CASE statement**: For categorizing users based on the number of gold badges.
- **STRING_AGG function**: To concatenate tag names into a single string.

The generated query provides a comprehensive view of users who are active contributors in the Stack Overflow community, along with their badge counts, rankings, and the tags they frequently use.
