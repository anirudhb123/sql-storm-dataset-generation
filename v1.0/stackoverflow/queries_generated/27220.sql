WITH TagCounts AS (
    SELECT
        unnest(string_to_array(substring(Tags, 2, length(Tags)-2), '><')) AS TagName,
        COUNT(*) AS PostCount
    FROM
        Posts
    WHERE
        PostTypeId = 1  -- Only questions
    GROUP BY
        TagName
),
ActiveUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COALESCE(SUM(b.Class = 1), 0) AS GoldBadges,
        COALESCE(SUM(b.Class = 2), 0) AS SilverBadges,
        COALESCE(SUM(b.Class = 3), 0) AS BronzeBadges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),
PostEngagement AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        COUNT(DISTINCT p.OwnerUserId) AS UniqueResponders
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'  -- Focus on last year's posts
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
    Posts p ON tc.TagName = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))
JOIN
    ActiveUsers au ON p.OwnerUserId = au.UserId
JOIN
    PostEngagement pe ON p.Id = pe.PostId
ORDER BY
    tc.PostCount DESC,
    au.GoldBadges DESC,
    pe.UpVotes DESC
LIMIT 50;
