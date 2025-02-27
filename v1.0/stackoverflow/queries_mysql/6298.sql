
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
        p.CreationDate >= NOW() - INTERVAL 1 YEAR
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
LEFT JOIN
    (SELECT
        p.Id,
        GROUP_CONCAT(t.TagName SEPARATOR ', ') AS Tags
    FROM
        Posts p
    JOIN
        (SELECT
            SUBSTRING_INDEX(SUBSTRING_INDEX(p.Tags, '><', n.n), '><', -1) AS tag
        FROM
            Posts p
        JOIN
            (SELECT
                @row := @row + 1 AS n
            FROM
                (SELECT 1 UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION
                 SELECT 6 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 10) numbers,
                (SELECT @row := 0) r) n
            ON CHAR_LENGTH(p.Tags) - CHAR_LENGTH(REPLACE(p.Tags, '><', '')) >= n.n - 1) t_tag ON t_tag.tag IS NOT NULL
    JOIN
        Tags t ON t.TagName = t_tag.tag
    GROUP BY
        p.Id) ps ON tp.Id = ps.Id
ORDER BY
    tp.Score DESC;
