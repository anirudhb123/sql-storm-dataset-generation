WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rnk
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId IN (1, 2) -- Considering only Questions and Answers
),

TaggedPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerDisplayName,
        STRING_AGG(t.TagName, ', ') AS Tags
    FROM
        RankedPosts rp
    LEFT JOIN
        Posts p ON rp.PostId = p.Id
    LEFT JOIN
        Tags t ON t.Id IN (SELECT UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><'))::int)
    GROUP BY
        rp.PostId, rp.Title, rp.Body, rp.CreationDate, rp.ViewCount, rp.Score, rp.OwnerDisplayName
),

TopRankedPosts AS (
    SELECT
        *,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = tp.PostId) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = tp.PostId AND v.VoteTypeId = 2) AS UpVotes
    FROM
        TaggedPosts tp
    WHERE
        Rnk <= 10 -- Top 10 Posts
)

SELECT
    t.Title,
    t.OwnerDisplayName,
    t.Score,
    t.ViewCount,
    t.CommentCount,
    t.UpVotes,
    t.Tags,
    t.CreationDate,
    EXTRACT(EPOCH FROM NOW() - t.CreationDate) / 60 AS AgeInMinutes -- Age of the post in minutes
FROM
    TopRankedPosts t
ORDER BY
    t.Score DESC, t.ViewCount DESC;
