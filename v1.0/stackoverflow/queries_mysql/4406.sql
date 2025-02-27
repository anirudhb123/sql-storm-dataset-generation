
WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.OwnerUserId,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVoteCount,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVoteCount,
        @row_num := @row_num + 1 AS RowNum
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId,
        (SELECT @row_num := 0) AS rn
    WHERE
        p.CreationDate >= NOW() - INTERVAL 30 DAY
    GROUP BY
        p.Id,
        p.Title,
        p.CreationDate,
        p.OwnerUserId
),
TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(b.Class, 0)) AS BadgeCount,
        COUNT(DISTINCT p.Id) AS PostCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    LEFT JOIN
        Posts p ON u.Id = p.OwnerUserId
    WHERE
        u.Reputation > 1000
    GROUP BY
        u.Id,
        u.DisplayName
    HAVING
        COUNT(DISTINCT p.Id) > 5
),
PostedLinks AS (
    SELECT
        pl.PostId,
        COUNT(pl.RelatedPostId) AS RelatedPostCount
    FROM
        PostLinks pl
    GROUP BY
        pl.PostId
)
SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    u.DisplayName AS OwnerName,
    rp.CommentCount,
    rp.UpVoteCount,
    rp.DownVoteCount,
    COALESCE(pl.RelatedPostCount, 0) AS RelatedPosts,
    CASE
        WHEN u.Location IS NOT NULL AND u.Location <> '' THEN u.Location
        ELSE 'Location not provided'
    END AS UserLocation,
    CASE
        WHEN u.Reputation IS NULL THEN 'No Reputation'
        ELSE CAST(u.Reputation AS CHAR)
    END AS Reputation,
    t.BadgeCount,
    t.PostCount
FROM
    RecentPosts rp
JOIN
    Users u ON rp.OwnerUserId = u.Id
LEFT JOIN
    PostedLinks pl ON rp.PostId = pl.PostId
LEFT JOIN
    TopUsers t ON u.Id = t.UserId
WHERE
    rp.RowNum <= 10
ORDER BY
    rp.UpVoteCount DESC, rp.CommentCount DESC;
