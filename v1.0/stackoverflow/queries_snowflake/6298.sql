
WITH RankedPosts AS (
    SELECT
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        COUNT(c.Id) AS CommentCount,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        ROW_NUMBER() OVER (ORDER BY p.Score DESC, p.ViewCount DESC) AS Rank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp)
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Score, p.ViewCount, u.DisplayName
),
TopPosts AS (
    SELECT
        Id,
        Title,
        CreationDate,
        Score,
        ViewCount,
        OwnerDisplayName,
        CommentCount,
        UpVotes,
        DownVotes
    FROM
        RankedPosts
    WHERE
        Rank <= 10
)
SELECT
    tp.Title,
    tp.CreationDate,
    tp.Score,
    tp.ViewCount,
    tp.OwnerDisplayName,
    tp.CommentCount,
    tp.UpVotes,
    tp.DownVotes,
    ps.Tags
FROM
    TopPosts tp
LEFT JOIN (
    SELECT
        p.Id,
        LISTAGG(t.TagName, ', ') AS Tags
    FROM
        Posts p
    JOIN
        LATERAL FLATTEN(input => SPLIT(SUBSTR(p.Tags, 2, LENGTH(p.Tags)-2), '><')) AS tag ON tag IS NOT NULL
    JOIN
        Tags t ON t.TagName = tag.VALUE
    GROUP BY
        p.Id
) ps ON tp.Id = ps.Id
ORDER BY
    tp.Score DESC;
