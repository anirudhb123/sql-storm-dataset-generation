WITH TagCounts AS (
    SELECT
        tag.TagName,
        COUNT(DISTINCT post.Id) AS PostCount
    FROM
        Tags AS tag
    LEFT JOIN
        Posts AS post ON post.Tags LIKE CONCAT('%<', tag.TagName, '>%')
    GROUP BY
        tag.TagName
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END) AS GoldCount,
        SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END) AS SilverCount,
        SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END) AS BronzeCount
    FROM
        Users AS u
    LEFT JOIN
        Badges AS b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostStatistics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(ac.AcceptedAnswerId, 0) AS HasAcceptedAnswer,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts AS p
    LEFT JOIN
        Posts AS ac ON p.AcceptedAnswerId = ac.Id
    LEFT JOIN
        Comments AS c ON p.Id = c.PostId
    LEFT JOIN
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags)-2), '><') AS tag_names ON TRUE
    LEFT JOIN
        Tags AS t ON t.TagName = tag_names
    WHERE
        p.PostTypeId = 1 -- Questions only
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.ViewCount, p.Score, ac.AcceptedAnswerId
),
HighScoringUsers AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        u.Reputation,
        COALESCE(b.BadgeCount, 0) AS BadgeCount,
        SUM(ps.ViewCount) AS TotalViews
    FROM 
        Users AS u
    LEFT JOIN 
        UserBadges AS b ON u.Id = b.UserId
    LEFT JOIN 
        Posts AS p ON u.Id = p.OwnerUserId
    LEFT JOIN 
        PostStatistics AS ps ON p.Id = ps.PostId
    WHERE 
        u.Reputation > 1000 -- Only users with high reputation
    GROUP BY 
        u.Id, u.DisplayName, u.Reputation, b.BadgeCount
)
SELECT 
    u.UserId,
    u.DisplayName,
    u.Reputation,
    u.BadgeCount,
    p.Title AS TopPostTitle,
    p.ViewCount AS TopPostViews,
    p.Score AS TopPostScore,
    p.Tags AS TopPostTags,
    tc.PostCount AS TagPostCount
FROM 
    HighScoringUsers AS u
INNER JOIN 
    PostStatistics AS p ON p.PostId = (
        SELECT p2.Id
        FROM Posts AS p2
        WHERE p2.OwnerUserId = u.UserId
        ORDER BY p2.Score DESC, p2.ViewCount DESC
        LIMIT 1
    )
LEFT JOIN 
    TagCounts AS tc ON tc.TagName IN (SELECT UNNEST(STRING_TO_ARRAY(p.Tags, ', ')))
WHERE 
    p.Title IS NOT NULL 
ORDER BY 
    u.Reputation DESC;
