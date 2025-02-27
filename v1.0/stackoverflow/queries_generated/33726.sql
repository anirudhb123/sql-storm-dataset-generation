WITH RecursivePostHierarchy AS (
    -- CTE for building a hierarchy of posts (parent-child relationships)
    SELECT
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM
        Posts
    WHERE
        ParentId IS NULL

    UNION ALL

    SELECT
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM
        Posts p
    INNER JOIN
        RecursivePostHierarchy rph ON p.ParentId = rph.Id
),

UserBadges AS (
    -- Aggregate user badge information
    SELECT
        u.Id AS UserId,
        COUNT(b.Id) AS BadgeCount,
        STRING_AGG(b.Name, ', ') AS Badges
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    GROUP BY
        u.Id
),

PostVoteInfo AS (
    -- Summary of votes for posts
    SELECT
        p.Id AS PostId,
        p.Title,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 2) AS UpVotes,
        COUNT(v.Id) FILTER (WHERE v.VoteTypeId = 3) AS DownVotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id, p.Title
),

PostHistorySummary AS (
    -- Getting history of posts with specific criteria
    SELECT
        p.Id AS PostId,
        p.Title,
        MAX(ph.CreationDate) AS LastEdited,
        COUNT(ph.Id) AS EditCount
    FROM
        Posts p
    LEFT JOIN
        PostHistory ph ON p.Id = ph.PostId
    WHERE
        ph.PostHistoryTypeId IN (4, 5, 6) -- Edit Title, Body, or Tags
    GROUP BY
        p.Id, p.Title
)

SELECT
    p.Id,
    p.Title,
    COALESCE(u.BadgeCount, 0) AS UserBadgeCount,
    COALESCE(v.UpVotes, 0) AS PostUpVotes,
    COALESCE(v.DownVotes, 0) AS PostDownVotes,
    COALESCE(h.EditCount, 0) AS PostEditCount,
    r.DocumentCount AS RelatedQuestionCount,
    CASE
        WHEN p.AcceptedAnswerId IS NOT NULL THEN 'Has Accepted Answer'
        ELSE 'No Accepted Answer'
    END AS AnswerStatus
FROM
    Posts p
LEFT JOIN
    UserBadges u ON p.OwnerUserId = u.UserId
LEFT JOIN
    PostVoteInfo v ON p.Id = v.PostId
LEFT JOIN
    (SELECT
        pl.PostId,
        COUNT(pl.RelatedPostId) AS DocumentCount
    FROM
        PostLinks pl
    GROUP BY
        pl.PostId) r ON p.Id = r.PostId
LEFT JOIN
    PostHistorySummary h ON p.Id = h.PostId
WHERE
    p.CreationDate > CURRENT_DATE - INTERVAL '1 year'
    AND p.Score > 0
ORDER BY
    p.Title ASC;
