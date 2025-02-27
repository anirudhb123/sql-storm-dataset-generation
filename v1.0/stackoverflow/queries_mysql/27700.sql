
WITH RecentPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        p.CreationDate,
        p.ViewCount,
        u.DisplayName AS OwnerDisplayName,
        (SELECT COUNT(*) FROM Comments c WHERE c.PostId = p.Id) AS CommentCount,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 2) AS UpVotes,
        (SELECT COUNT(*) FROM Votes v WHERE v.PostId = p.Id AND v.VoteTypeId = 3) AS DownVotes,
        GROUP_CONCAT(DISTINCT t.TagName ORDER BY t.TagName SEPARATOR ', ') AS Tags
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN
        (SELECT
            SUBSTRING_INDEX(SUBSTRING_INDEX(Tags, '><', numbers.n), '><', -1) AS TagName,
            p.Id
        FROM
            (SELECT 1 AS n UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5) numbers
        JOIN
            Posts p ON CHAR_LENGTH(Tags)
            -CHAR_LENGTH(REPLACE(Tags, '><', '')) >= numbers.n - 1) t ON p.Id = t.Id
    WHERE
        p.CreationDate >= '2024-10-01 12:34:56' - INTERVAL 30 DAY
    GROUP BY
        p.Id, p.Title, p.Body, p.CreationDate, p.ViewCount, u.DisplayName
),
PostStatistics AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.OwnerDisplayName,
        rp.CreationDate,
        rp.ViewCount,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Tags,
        (rp.UpVotes - rp.DownVotes) AS NetVotes
    FROM
        RecentPosts rp
)
SELECT
    ps.PostId,
    ps.Title,
    ps.OwnerDisplayName,
    ps.CreationDate,
    ps.ViewCount,
    ps.CommentCount,
    ps.UpVotes,
    ps.DownVotes,
    ps.NetVotes,
    CASE 
        WHEN ps.NetVotes > 0 THEN 'Positive'
        WHEN ps.NetVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM
    PostStatistics ps
ORDER BY
    ps.NetVotes DESC,
    ps.ViewCount DESC
LIMIT 10;
