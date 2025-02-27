WITH RecursivePostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        1 AS Level
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Questions
    UNION ALL
    SELECT
        p2.Id AS PostId,
        p2.Title,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        rh.Level + 1
    FROM
        Posts p2
    INNER JOIN
        Posts p1 ON p2.ParentId = p1.Id
    INNER JOIN
        RecursivePostHierarchy rh ON p1.Id = rh.PostId
),

PostVoteCounts AS (
    SELECT
        p.Id,
        COUNT(CASE WHEN v.VoteTypeId = 2 THEN 1 END) AS Upvotes,
        COUNT(CASE WHEN v.VoteTypeId = 3 THEN 1 END) AS Downvotes,
        COUNT(v.Id) AS TotalVotes
    FROM
        Posts p
    LEFT JOIN
        Votes v ON p.Id = v.PostId
    GROUP BY
        p.Id
),

TopUsers AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(u.Reputation) AS TotalReputation,
        RANK() OVER (ORDER BY SUM(u.Reputation) DESC) AS ReputationRank
    FROM
        Users u
    GROUP BY
        u.Id
),

PostMetrics AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        p.AcceptedAnswerId,
        up.Upvotes,
        down.Downvotes,
        ph.Level AS HierarchyLevel,
        COALESCE(th.ReputationRank, 1000) AS TopUserRank,
        CASE 
            WHEN p.ClosedDate IS NOT NULL THEN 'Closed' 
            ELSE 'Open' 
        END AS PostStatus
    FROM
        Posts p
    LEFT JOIN
        PostVoteCounts up ON p.Id = up.Id
    LEFT JOIN
        PostVoteCounts down ON p.Id = down.Id
    LEFT JOIN
        RecursivePostHierarchy ph ON p.Id = ph.PostId
    LEFT JOIN
        TopUsers th ON p.OwnerUserId = th.UserId
    WHERE
        p.CreationDate >= '2021-01-01' -- Filter for recent posts
)

SELECT
    pm.PostId,
    pm.Title,
    pm.CreationDate,
    pm.Upvotes,
    pm.Downvotes,
    pm.HierarchyLevel,
    pm.TopUserRank,
    pm.PostStatus
FROM
    PostMetrics pm
WHERE
    pm.TopUserRank < 10
ORDER BY
    pm.HierarchyLevel DESC,
    pm.Upvotes DESC;

