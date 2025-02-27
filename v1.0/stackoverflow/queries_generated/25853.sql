WITH PostTags AS (
    SELECT
        p.Id AS PostId,
        unnest(string_to_array(substring(p.Tags, 2, length(p.Tags) - 2), '><')) AS Tag
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Only questions
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS BadgeNames
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
HighlyActivePosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        COUNT(DISTINCT c.Id) AS CommentCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    WHERE
        p.PostTypeId = 1 -- Only questions
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount
    HAVING
        COUNT(DISTINCT c.Id) > 5 -- More than 5 comments
),
TagAnalytics AS (
    SELECT
        pt.Tag,
        COUNT(DISTINCT p.PostId) AS PostCount,
        AVG(p.ViewCount) AS AvgViewCount,
        AVG(u.Reputation) AS AvgUserReputation
    FROM
        PostTags pt
    JOIN
        Posts p ON pt.PostId = p.Id
    JOIN
        Users u ON p.OwnerUserId = u.Id
    GROUP BY
        pt.Tag
),
TopUsers AS (
    SELECT
        u.Id,
        u.DisplayName,
        u.Reputation,
        b.BadgeCount,
        b.BadgeNames
    FROM
        Users u
    JOIN
        UserBadges b ON u.Id = b.UserId
    WHERE
        u.Reputation > 1000 -- Users with high reputation
)
SELECT
    ta.Tag,
    ta.PostCount,
    ta.AvgViewCount,
    ta.AvgUserReputation,
    tu.DisplayName AS TopUser,
    tu.Reputation AS TopUserReputation,
    tu.BadgeCount,
    tu.BadgeNames,
    hap.Title AS ActivePostTitle,
    hap.CreationDate AS ActivePostDate
FROM
    TagAnalytics ta
JOIN
    TopUsers tu ON tu.Reputation = (
        SELECT MAX(Reputation)
        FROM TopUsers
    )
JOIN
    HighlyActivePosts hap ON hap.PostId IN (
        SELECT PostId
        FROM HighlyActivePosts
    )
ORDER BY
    ta.PostCount DESC, ta.Tag;
