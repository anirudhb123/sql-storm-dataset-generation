WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ParentId,
        0 AS Level
    FROM
        Posts p
    WHERE
        p.ParentId IS NULL -- Starting with top-level posts (questions)

    UNION ALL

    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.ParentId,
        r.Level + 1
    FROM
        Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
PostVoteCounts AS (
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
UserReputation AS (
    SELECT
        u.Id AS UserId,
        u.Reputation,
        COUNT(DISTINCT b.Id) AS BadgeCount
    FROM
        Users u
    LEFT JOIN
        Badges b ON u.Id = b.UserId
    WHERE
        u.Reputation > 0
    GROUP BY
        u.Id, u.Reputation
),
RecentPostHistory AS (
    SELECT
        p.Id AS PostId,
        MAX(ph.CreationDate) AS LastModifiedDate
    FROM
        Posts p
    JOIN
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY
        p.Id
)
SELECT
    ph.PostId,
    ph.Title,
    ph.CreationDate,
    COALESCE(u.DisplayName, 'Community User') AS Owner,
    COALESCE(pc.UpVotes, 0) AS UpVotes,
    COALESCE(pc.DownVotes, 0) AS DownVotes,
    u.Reputation,
    u.BadgeCount,
    rph.Level,
    rph.ParentId,
    phm.LastModifiedDate,
    CASE
        WHEN phm.LastModifiedDate < CURRENT_TIMESTAMP - INTERVAL '1 year' THEN 'Outdated'
        ELSE 'Active'
    END AS Status
FROM
    Posts AS ph
LEFT JOIN
    Users AS u ON ph.OwnerUserId = u.Id
LEFT JOIN
    PostVoteCounts AS pc ON ph.Id = pc.PostId
LEFT JOIN
    UserReputation AS u ON ph.OwnerUserId = u.UserId
LEFT JOIN
    RecursivePostHierarchy AS rph ON ph.Id = rph.PostId
LEFT JOIN
    RecentPostHistory AS phm ON ph.Id = phm.PostId
WHERE
    ph.CreationDate > CURRENT_TIMESTAMP - INTERVAL '2 year'
ORDER BY
    ph.Score DESC,
    ph.CreationDate ASC
FETCH FIRST 100 ROWS ONLY;
