WITH RecursivePostHierarchy AS (
    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        1 AS Level,
        p.CreationDate
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Starting with Questions
    UNION ALL
    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        r.Level + 1,
        p.CreationDate
    FROM
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.Id
),
PostVoteStats AS (
    SELECT
        p.Id AS PostId,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
),
PostWithHistory AS (
    SELECT
        ph.PostId,
        COUNT(CASE WHEN ph.PostHistoryTypeId = 10 THEN 1 END) AS CloseCount,
        COUNT(CASE WHEN ph.PostHistoryTypeId IN (11, 12) THEN 1 END) AS ReopenDeleteCount,
        MIN(ph.CreationDate) AS FirstEdit
    FROM
        PostHistory ph
    GROUP BY
        ph.PostId
)
SELECT
    r.Id AS QuestionId,
    r.Title AS QuestionTitle,
    pws.UpVotes,
    pws.DownVotes,
    pws.TotalVotes,
    pwh.CloseCount,
    pwh.ReopenDeleteCount,
    r.Level,
    r.CreationDate,
    pwh.FirstEdit AS InitialEditDate
FROM
    RecursivePostHierarchy r
LEFT JOIN 
    PostVoteStats pws ON r.Id = pws.PostId
LEFT JOIN 
    PostWithHistory pwh ON r.Id = pwh.PostId
WHERE
    r.Level = 1  -- Only interested in questions (top level)
ORDER BY
    r.CreationDate DESC,
    pws.UpVotes DESC,
    pwh.CloseCount ASC;
