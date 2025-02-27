
WITH TagCounts AS (
    SELECT
        SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    JOIN (
        SELECT 1 AS n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5
        UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9 UNION ALL SELECT 10
    ) numbers ON CHAR_LENGTH(Tags) - CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1
    WHERE
        PostTypeId = 1  
    GROUP BY
        TagName
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(CASE WHEN b.Class = 1 THEN 1 ELSE 0 END), 0) AS GoldBadges,
        COALESCE(SUM(CASE WHEN b.Class = 2 THEN 1 ELSE 0 END), 0) AS SilverBadges,
        COALESCE(SUM(CASE WHEN b.Class = 3 THEN 1 ELSE 0 END), 0) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName
),
PostEngagement AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueResponders
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL 1 YEAR  
    GROUP BY
        p.Id, p.Title
)
SELECT
    tc.TagName,
    tc.PostCount,
    au.UserId,
    au.DisplayName,
    au.GoldBadges,
    au.SilverBadges,
    au.BronzeBadges,
    pe.PostId,
    pe.Title,
    pe.CommentCount,
    pe.UpVotes,
    pe.DownVotes,
    pe.UniqueResponders
FROM
    TagCounts tc
JOIN
    Posts p ON FIND_IN_SET(tc.TagName, SUBSTRING(SUBSTRING_INDEX(p.Tags, '>', -1), 2)) > 0
JOIN
    ActiveUsers au ON p.OwnerUserId = au.UserId
JOIN
    PostEngagement pe ON p.Id = pe.PostId
ORDER BY
    tc.PostCount DESC,
    au.GoldBadges DESC,
    pe.UpVotes DESC
LIMIT 50;
