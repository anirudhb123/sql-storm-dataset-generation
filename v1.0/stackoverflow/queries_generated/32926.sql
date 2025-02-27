WITH RecursivePostHierarchy AS (
    -- CTE to generate a hierarchy of posts, especially for questions and their answers
    SELECT
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        0 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1  -- Questions
    UNION ALL
    SELECT
        p.Id,
        p.ParentId,
        p.Title,
        Level + 1
    FROM
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserPostStats AS (
    -- CTE to get user statistics related to posts
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(p.Id) AS PostCount,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBountyAmount,
        SUM(CASE WHEN p.Score > 0 THEN 1 ELSE 0 END) AS PositivePostCount
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 9 -- BountyClose
    GROUP BY
        u.Id
),
VoteSummary AS (
    -- CTE for summarizing votes on posts
    SELECT
        p.Id AS PostId,
        SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM
        Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
)
SELECT
    u.DisplayName,
    ups.PostCount,
    ups.TotalBountyAmount,
    ups.PositivePostCount,
    ph.Level,
    ph.Title AS QuestionTitle,
    vs.UpVotes,
    vs.DownVotes
FROM
    UserPostStats ups
INNER JOIN RecursivePostHierarchy ph ON ups.UserId = (
    SELECT OwnerUserId 
    FROM Posts p 
    WHERE p.Id = ph.PostId
)
LEFT JOIN VoteSummary vs ON vs.PostId = ph.PostId
WHERE
    ups.PostCount > 0
  AND (
        vs.UpVotes - vs.DownVotes > 5
        OR ups.TotalBountyAmount > 0
      )
ORDER BY
    ups.PostCount DESC, ups.TotalBountyAmount DESC, vs.UpVotes DESC;
