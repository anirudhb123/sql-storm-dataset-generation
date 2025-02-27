WITH TagsCTE AS (
    SELECT
        t.Id AS TagId,
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM
        Tags t
    LEFT JOIN
        Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        t.Id, t.TagName
    HAVING
        COUNT(p.Id) > 0
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldBadges,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverBadges,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(uc.BadgeCount, 0) AS UserBadgeCount,
        COALESCE(uc.GoldBadges, 0) AS UserGoldBadges,
        COALESCE(uc.SilverBadges, 0) AS UserSilverBadges,
        COALESCE(uc.BronzeBadges, 0) AS UserBronzeBadges,
        COUNT(c.Id) AS CommentCount,
        AVG(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS AvgUpVotes,
        AVG(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS AvgDownVotes,
        STRING_AGG(tg.TagName, ', ') AS TagsList
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        UserBadges uc ON p.OwnerUserId = uc.UserId
    LEFT JOIN
        TagsCTE tg ON p.Tags LIKE '%' || tg.TagName || '%'
    GROUP BY
        p.Id, p.Title, p.CreationDate, uc.BadgeCount, uc.GoldBadges, uc.SilverBadges, uc.BronzeBadges
),
BenchmarkResults AS (
    SELECT
        ps.*,
        ROW_NUMBER() OVER (ORDER BY ps.UserBadgeCount DESC, ps.CreationDate DESC) AS Rank
    FROM
        PostStatistics ps
)
SELECT
    Rank,
    PostId,
    Title,
    CreationDate,
    UserBadgeCount,
    UserGoldBadges,
    UserSilverBadges,
    UserBronzeBadges,
    CommentCount,
    AvgUpVotes,
    AvgDownVotes,
    TagsList
FROM
    BenchmarkResults
WHERE
    UserBadgeCount > 0
ORDER BY
    Rank
LIMIT 10;
