WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.Body,
        COALESCE(NULLIF(LENGTH(p.Body), 0), NULL) AS BodyLength,
        COUNT(c.Id) AS CommentCount,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        ROW_NUMBER() OVER (PARTITION BY p.OwnerUserId ORDER BY p.CreationDate DESC) AS PostRank,
        STRING_AGG(DISTINCT t.TagName, ', ') AS Tags
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    LEFT JOIN
        STRING_TO_ARRAY(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><') AS tag ON t.TagName = tag
    LEFT JOIN
        Tags t ON t.TagName = TRIM(BOTH '<>' FROM split_part(SUBSTRING(p.Tags, 2, LENGTH(p.Tags) - 2), '><', n)) 
    GROUP BY
        p.Id, p.Title, p.Body
),

TopPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.Body,
        rp.BodyLength,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.Tags
    FROM
        RankedPosts rp
    WHERE
        rp.PostRank = 1
)

SELECT
    p.PostId,
    p.Title,
    p.Body,
    p.BodyLength,
    p.CommentCount,
    p.UpVotes,
    p.DownVotes,
    p.Tags,
    CASE
        WHEN p.UpVotes - p.DownVotes > 0 THEN 'Positive'
        WHEN p.UpVotes - p.DownVotes < 0 THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment,
    COUNT(ph.Id) AS TotalHistoryChanges
FROM
    TopPosts p
LEFT JOIN
    PostHistory ph ON p.PostId = ph.PostId
GROUP BY
    p.PostId, p.Title, p.Body, p.BodyLength, p.CommentCount, p.UpVotes, p.DownVotes, p.Tags
ORDER BY
    p.UpVotes - p.DownVotes DESC,
    p.CommentCount DESC;
