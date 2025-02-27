WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        CAST(0 AS INT) AS Level
    FROM
        Posts p
    WHERE
        p.ParentId IS NULL  -- Starting point: Root posts (Questions)

    UNION ALL

    SELECT
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.PostTypeId,
        p.ParentId,
        p.CreationDate,
        Level + 1
    FROM
        Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.PostId
),
VoteSummary AS (
    SELECT
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes,
        COUNT(*) AS TotalVotes
    FROM
        Votes
    GROUP BY
        PostId
),
PostTags AS (
    SELECT
        PostId,
        STRING_AGG(TagName, ', ') AS Tags
    FROM
        Tags t
    INNER JOIN Posts p ON p.Tags LIKE '%' || t.TagName || '%'
    GROUP BY
        PostId
),
PostHistoryFiltered AS (
    SELECT
        ph.PostId,
        MAX(CASE WHEN pht.Name = 'Initial Title' THEN ph.CreationDate END) AS InitialTitleDate,
        MAX(CASE WHEN pht.Name = 'Post Closed' THEN ph.CreationDate END) AS ClosedDate,
        COUNT(*) FILTER (WHERE ph.PostHistoryTypeId = 12) AS DeletionCount
    FROM
        PostHistory ph
    INNER JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    GROUP BY
        ph.PostId
)
SELECT
    p.Id AS PostId,
    p.Title,
    u.DisplayName AS OwnerDisplayName,
    p.CreationDate,
    COALESCE(ps.UpVotes, 0) AS UpVoteCount,
    COALESCE(ps.DownVotes, 0) AS DownVoteCount,
    ph.InitialTitleDate,
    ph.ClosedDate,
    ph.DeletionCount,
    p.Tags,
    rph.Level AS PostLevel
FROM
    Posts p
LEFT JOIN Users u ON p.OwnerUserId = u.Id
LEFT JOIN VoteSummary ps ON p.Id = ps.PostId
LEFT JOIN PostTags pt ON p.Id = pt.PostId
LEFT JOIN PostHistoryFiltered ph ON p.Id = ph.PostId
LEFT JOIN RecursivePostHierarchy rph ON p.Id = rph.PostId
WHERE
    (p.PostTypeId = 1 OR p.PostTypeId = 2) -- Only Questions or Answers
    AND u.Reputation > 50 -- Users with reputation greater than 50
ORDER BY
    p.CreationDate DESC,
    rph.Level,
    p.Score DESC;
