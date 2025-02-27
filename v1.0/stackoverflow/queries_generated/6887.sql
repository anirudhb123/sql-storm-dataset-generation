WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        p.AnswerCount,
        u.DisplayName AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= NOW() - INTERVAL '1 year'
),
TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.AnswerCount,
        rp.OwnerDisplayName
    FROM
        RankedPosts rp
    WHERE
        rp.Rank <= 10
)
SELECT
    tp.*,
    COALESCE(SUM(v.VoteTypeId = 2)::int, 0) AS UpVotes,
    COALESCE(SUM(v.VoteTypeId = 3)::int, 0) AS DownVotes,
    COUNT(c.Id) AS CommentCount,
    ARRAY_AGG(DISTINCT t.TagName) AS Tags
FROM
    TopPosts tp
LEFT JOIN
    Votes v ON tp.PostId = v.PostId
LEFT JOIN
    Comments c ON tp.PostId = c.PostId
LEFT JOIN
    LATERAL (
        SELECT
            unnest(string_to_array(tp.Tags, ', ')) AS TagName
    ) AS t ON true
GROUP BY
    tp.PostId, tp.Title, tp.CreationDate, tp.Score, tp.ViewCount, tp.AnswerCount, tp.OwnerDisplayName
ORDER BY
    tp.Score DESC, tp.ViewCount DESC;
