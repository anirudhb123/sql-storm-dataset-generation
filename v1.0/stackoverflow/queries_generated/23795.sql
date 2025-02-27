WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC) AS RankByScore,
        COUNT(c.Id) AS CommentCount,
        SUM(v.VoteTypeId = 2) AS UpVotes,
        SUM(v.VoteTypeId = 3) AS DownVotes,
        (SELECT COUNT(DISTINCT t.TagName)
         FROM Tags t
         WHERE t.Id IN (SELECT unnest(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[]))) ) AS UniqueTagCount
    FROM
        Posts p
    LEFT JOIN
        Comments c ON c.PostId = p.Id
    LEFT JOIN
        Votes v ON v.PostId = p.Id
    WHERE
        p.CreationDate >= CURRENT_DATE - INTERVAL '30 days'
    GROUP BY
        p.Id
    HAVING
        p.Score >= 10 AND
        (SUM(v.VoteTypeId = 2) - SUM(v.VoteTypeId = 3)) > 5
),

FilteredPosts AS (
    SELECT
        rp.PostId,
        rp.Title,
        rp.CreationDate,
        rp.Score,
        rp.ViewCount,
        rp.RankByScore,
        rp.CommentCount,
        rp.UpVotes,
        rp.DownVotes,
        rp.UniqueTagCount
    FROM
        RankedPosts rp
    WHERE
        rp.RankByScore <= 5
),

PostHistoryAggregate AS (
    SELECT
        ph.PostId,
        MAX(CASE WHEN ph.PostHistoryTypeId IN (10, 11) THEN ph.CreationDate END) AS LastClosedReopened
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)

SELECT
    fp.PostId,
    fp.Title,
    fp.CreationDate,
    fp.Score,
    fp.ViewCount,
    fp.CommentCount,
    fp.UpVotes,
    fp.DownVotes,
    fp.UniqueTagCount,
    COALESCE(ph.LastClosedReopened, 'Never') AS ClosureStatus,
    CASE 
        WHEN fp.PostId IN (SELECT DISTINCT RelatedPostId FROM PostLinks pl WHERE pl.LinkTypeId = 3) THEN 'Yes'
        ELSE 'No'
    END AS IsDuplicate,
    CASE 
        WHEN fp.UpVotes > fp.DownVotes THEN 'Positive'
        WHEN fp.UpVotes < fp.DownVotes THEN 'Negative'
        ELSE 'Neutral'
    END AS VoteSentiment
FROM
    FilteredPosts fp
LEFT JOIN
    PostHistoryAggregate ph ON ph.PostId = fp.PostId
ORDER BY
    fp.Score DESC, fp.ViewCount DESC;
