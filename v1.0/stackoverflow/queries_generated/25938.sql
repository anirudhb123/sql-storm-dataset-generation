WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        ARRAY_AGG(DISTINCT t.TagName) AS Tags,
        DENSE_RANK() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Tags t ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    WHERE
        p.PostTypeId = 1 -- We're only interested in questions
    GROUP BY
        p.Id
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.Tags
    FROM
        RankedPosts rp
    WHERE
        rp.Rank <= 10
),
UserStats AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(b.Id) AS BadgeCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Users u
    LEFT JOIN
        Badges b ON b.UserId = u.Id
    LEFT JOIN
        Votes v ON v.UserId = u.Id
    GROUP BY
        u.Id
),
PostInteractions AS (
    SELECT
        p.Id AS PostId,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT l.RelatedPostId) AS RelatedPostCount,
        MAX(ph.CreationDate) AS LastEditDate
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        PostLinks l ON l.PostId = p.Id
    LEFT JOIN
        PostHistory ph ON ph.PostId = p.Id
    GROUP BY
        p.Id
)
SELECT
    tp.PostId,
    tp.Title,
    tp.CreationDate,
    tp.ViewCount,
    tp.Score,
    tp.Tags,
    us.DisplayName AS Author,
    us.BadgeCount,
    us.UpVotes,
    us.DownVotes,
    pi.CommentCount,
    pi.RelatedPostCount,
    pi.LastEditDate
FROM
    TopPosts tp
JOIN
    Users us ON us.Id = (SELECT OwnerUserId FROM Posts WHERE Id = tp.PostId)
JOIN
    PostInteractions pi ON pi.PostId = tp.PostId
ORDER BY
    tp.Score DESC, tp.CreationDate DESC;
