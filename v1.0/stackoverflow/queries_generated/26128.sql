WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        COUNT(c.Id) AS CommentCount,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 1 THEN 1 ELSE 0 END), 0) AS AcceptedVotes,
        ROW_NUMBER() OVER (PARTITION BY p.Tags ORDER BY p.ViewCount DESC) AS RankByTags
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.PostTypeId = 1 -- Only considering questions
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount
),
TopRankedPosts AS (
    SELECT * 
    FROM RankedPosts 
    WHERE RankByTags = 1 -- Top post for each tag
),
UserBadges AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        b.Name AS BadgeName,
        b.Class,
        COUNT(b.Id) AS BadgeCount
    FROM
        Users u
    JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id, u.DisplayName, b.Name, b.Class
    HAVING
        COUNT(b.Id) > 1 -- Users with more than one badge
),
PostWithBadges AS (
    SELECT
        trp.PostId,
        trp.Title,
        trp.CreationDate,
        trp.ViewCount,
        ub.DisplayName,
        STRING_AGG(ub.BadgeName, ', ') AS BadgeNames
    FROM
        TopRankedPosts trp
    JOIN
        Users u ON trp.OwnerUserId = u.Id
    JOIN
        UserBadges ub ON u.Id = ub.UserId
    GROUP BY
        trp.PostId, trp.Title, trp.CreationDate, trp.ViewCount, ub.DisplayName
)
SELECT
    pwb.PostId,
    pwb.Title,
    pwb.CreationDate,
    pwb.ViewCount,
    pwb.DisplayName AS Author,
    pwb.BadgeNames
FROM
    PostWithBadges pwb
ORDER BY
    pwb.ViewCount DESC
LIMIT 10; 
