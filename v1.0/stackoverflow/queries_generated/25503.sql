WITH UserMetrics AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        u.Views,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges,
        COUNT(DISTINCT p.Id) AS PostCount,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM Users u
    LEFT JOIN Badges b ON u.Id = b.UserId
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id, u.DisplayName, u.Reputation, u.Views
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(DISTINCT p.Id) AS UsageCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, '><')::int[])
    GROUP BY t.TagName
    ORDER BY UsageCount DESC
    LIMIT 10
),
UserPostDetails AS (
    SELECT 
        um.UserId,
        um.DisplayName,
        um.Reputation,
        um.GoldBadges,
        um.SilverBadges,
        um.BronzeBadges,
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.AnswerCount,
        pt.Name AS PostType
    FROM UserMetrics um
    JOIN Posts p ON um.UserId = p.OwnerUserId
    JOIN PostTypes pt ON p.PostTypeId = pt.Id
)

SELECT 
    upd.DisplayName AS UserName,
    upd.Reputation,
    upd.GoldBadges,
    upd.SilverBadges,
    upd.BronzeBadges,
    upd.Title AS PostTitle,
    upd.CreationDate AS PostCreationDate,
    upd.ViewCount AS PostViewCount,
    upd.AnswerCount,
    pt.Name AS PostTypeName,
    ARRAY_AGG(pt.Name) FILTER (WHERE pt.Name IS NOT NULL) AS RelatedPostTypes,
    (SELECT COUNT(DISTINCT p2.Id) 
     FROM Posts p2 
     WHERE p2.Tags LIKE '%' || CASE WHEN ARRAY_LENGTH(split_part(popular.Tags, ',', 1), 1) > 0 THEN split_part(popular.Tags, ',', 1) END || '%') AS PopularTagUsage
FROM UserPostDetails upd
JOIN PopularTags popular ON popular.UsageCount > 0
JOIN PostTypes pt ON upd.PostType = pt.Name
GROUP BY upd.UserId, upd.DisplayName, upd.Reputation, upd.GoldBadges, upd.SilverBadges, upd.BronzeBadges, upd.Title, upd.CreationDate, upd.ViewCount, upd.AnswerCount
ORDER BY upd.Reputation DESC, PostViewCount DESC;
