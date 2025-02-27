WITH RankedPosts AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.Score,
        p.ViewCount,
        COALESCE(u.DisplayName, 'Community') AS OwnerDisplayName,
        ROW_NUMBER() OVER (PARTITION BY p.PostTypeId ORDER BY p.Score DESC, p.CreationDate DESC) AS PostRank
    FROM
        Posts p
    LEFT JOIN
        Users u ON p.OwnerUserId = u.Id
    WHERE
        p.PostTypeId IN (1, 2) -- Focusing on Questions and Answers
),
PostHistoryDetails AS (
    SELECT
        ph.PostId,
        ph.Comment AS CloseComment,
        ph.CreationDate AS CloseDate,
        pht.Name AS HistoryType
    FROM
        PostHistory ph
    JOIN
        PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE
        ph.PostHistoryTypeId IN (10, 11) -- Only consider post closed and reopened events
),
RecentVotes AS (
    SELECT
        v.PostId,
        COUNT(CASE WHEN vt.Id = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN vt.Id = 3 THEN 1 END) AS Downvotes
    FROM
        Votes v
    JOIN
        VoteTypes vt ON v.VoteTypeId = vt.Id
    WHERE
        v.CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY
        v.PostId
)

SELECT
    rp.PostId,
    rp.Title,
    rp.CreationDate,
    rp.OwnerDisplayName,
    rp.Score,
    rp.ViewCount,
    COALESCE(phd.CloseComment, 'Not Closed') AS CloseComment,
    COALESCE(phd.CloseDate, 'Never') AS CloseDate,
    COALESCE(rv.Upvotes, 0) - COALESCE(rv.Downvotes, 0) AS NetVotes,
    CASE 
        WHEN COALESCE(rv.Upvotes, 0) > COALESCE(rv.Downvotes, 0) THEN 'Trending'
        WHEN COALESCE(rv.Upvotes, 0) < COALESCE(rv.Downvotes, 0) THEN 'Declining'
        ELSE 'Neutral' 
    END AS VoteTrend
FROM
    RankedPosts rp
LEFT JOIN
    PostHistoryDetails phd ON rp.PostId = phd.PostId
LEFT JOIN
    RecentVotes rv ON rp.PostId = rv.PostId
WHERE
    rp.PostRank = 1 -- Get only the highest-ranked post of each type
ORDER BY
    rp.Score DESC, rp.CreationDate DESC;

