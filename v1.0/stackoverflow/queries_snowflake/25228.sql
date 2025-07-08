
WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Body,
        p.Tags,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 2 THEN v.UserId END) AS UpVoteCount, 
        COUNT(DISTINCT CASE WHEN v.VoteTypeId = 3 THEN v.UserId END) AS DownVoteCount, 
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.CreationDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN
        Comments c ON p.Id = c.PostId
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    WHERE
        p.CreationDate >= DATEADD(year, -1, '2024-10-01 12:34:56'::timestamp) 
    GROUP BY
        p.Id, p.Title, p.CreationDate, p.Body, p.Tags
),
FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Body,
        rp.Tags,
        rp.CommentCount,
        rp.UpVoteCount,
        rp.DownVoteCount
    FROM
        RankedPosts rp
    WHERE
        rp.rn = 1 
)
SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.CommentCount,
    fp.UpVoteCount,
    fp.DownVoteCount,
    (fp.UpVoteCount - fp.DownVoteCount) AS NetVoteScore,
    ARRAY_LENGTH(SPLIT(fp.Tags, '><')) AS TagCount,
    CASE
        WHEN fp.UpVoteCount > fp.DownVoteCount THEN 'Positive'
        WHEN fp.UpVoteCount < fp.DownVoteCount THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM
    FilteredPosts fp
ORDER BY
    NetVoteScore DESC
LIMIT 50;
