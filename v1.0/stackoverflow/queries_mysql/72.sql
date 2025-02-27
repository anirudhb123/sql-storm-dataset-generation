
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        u.DisplayName AS OwnerName,
        RANK() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.CreationDate >= CURDATE() - INTERVAL 1 YEAR
),
RecentVotes AS (
    SELECT
        v.PostId,
        COUNT(CASE WHEN vt.Name = 'UpMod' THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN vt.Name = 'DownMod' THEN 1 END) AS DownVotes
    FROM
        Votes v
    JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE
        v.CreationDate >= CURDATE() - INTERVAL 6 MONTH
    GROUP BY
        v.PostId
),
Combined AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.ViewCount,
        rp.Score,
        rp.OwnerName,
        COALESCE(rv.UpVotes, 0) AS UpVotes,
        COALESCE(rv.DownVotes, 0) AS DownVotes,
        rp.PostRank
    FROM
        RankedPosts rp
    LEFT JOIN
        RecentVotes rv ON rp.PostId = rv.PostId
)
SELECT
    c.*,
    (CASE
        WHEN c.UpVotes > c.DownVotes THEN 'Positive'
        WHEN c.UpVotes < c.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END) AS Sentiment,
    CONCAT('Post Title: ', c.Title, ' | Owner: ', c.OwnerName) AS Summary
FROM
    Combined c
WHERE
    c.PostRank = 1
GROUP BY
    c.PostId,
    c.Title,
    c.CreationDate,
    c.ViewCount,
    c.Score,
    c.OwnerName,
    c.UpVotes,
    c.DownVotes,
    c.PostRank
ORDER BY
    c.Score DESC, c.CreationDate DESC
LIMIT 100 OFFSET 0;
