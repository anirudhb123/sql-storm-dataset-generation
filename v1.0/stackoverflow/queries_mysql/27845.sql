
WITH TagDetails AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Tags,
        SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', numbers.n), '><', -1) AS SplitTags
    FROM
        Posts p
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL 
        SELECT 4 UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL 
        SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL 
        SELECT 10) numbers ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= numbers.n - 1
    WHERE
        p.PostTypeId = 1 
),
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, u.Reputation
),
PostStats AS (
    SELECT
        p.OwnerUserId,
        COUNT(p.Id) AS TotalPosts,
        COUNT(DISTINCT p.AcceptedAnswerId) AS AcceptedAnswers,
        AVG(p.Score) AS AvgScore
    FROM
        Posts p
    GROUP BY
        p.OwnerUserId
)
SELECT
    ud.DisplayName,
    ud.Reputation,
    ud.BadgeCount,
    ud.GoldBadges,
    ud.SilverBadges,
    ud.BronzeBadges,
    ps.TotalPosts,
    ps.AcceptedAnswers,
    ps.AvgScore,
    GROUP_CONCAT(DISTINCT td.SplitTags) AS UniqueTags,
    COUNT(td.PostId) AS QuestionsCount
FROM
    UserReputation ud
JOIN
    PostStats ps ON ud.UserId = ps.OwnerUserId
LEFT JOIN
    TagDetails td ON ps.OwnerUserId = (
        SELECT OwnerUserId FROM Posts WHERE Id = td.PostId
    )
GROUP BY
    ud.DisplayName, ud.Reputation, ud.BadgeCount, ud.GoldBadges, 
    ud.SilverBadges, ud.BronzeBadges, ps.TotalPosts, 
    ps.AcceptedAnswers, ps.AvgScore
ORDER BY
    ud.Reputation DESC, ps.TotalPosts DESC;
