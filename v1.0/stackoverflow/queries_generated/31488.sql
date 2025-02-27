WITH RECURSIVE PostHierarchy AS (
    SELECT
        p.Id AS PostId,
        p.Title,
        p.PostTypeId,
        p.AcceptedAnswerId,
        p.ParentId,
        1 AS Depth
    FROM
        Posts p
    WHERE
        p.PostTypeId = 1 -- Start with Questions
    UNION ALL
    SELECT
        p2.Id AS PostId,
        p2.Title,
        p2.PostTypeId,
        p2.AcceptedAnswerId,
        p2.ParentId,
        ph.Depth + 1
    FROM
        Posts p2
    INNER JOIN PostHierarchy ph ON p2.ParentId = ph.PostId
),
LatestEdit AS (
    SELECT
        p.Id AS PostId,
        p.LastEditDate,
        p.LastEditorUserId,
        u.DisplayName AS EditorName,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastEditDate DESC) AS rn
    FROM
        Posts p
    LEFT JOIN Users u ON p.LastEditorUserId = u.Id
),
UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM
        Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Comments c ON u.Id = c.UserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    WHERE
        u.Reputation > 1000 -- Filter for active users
    GROUP BY
        u.Id
),
PostStatistics AS (
    SELECT
        ph.PostId,
        ph.Title,
        ph.Depth,
        COALESCE(l.LastEditDate, 'Never Edited') AS LastEditDate,
        l.EditorName,
        ua.TotalPosts,
        ua.TotalComments,
        ua.TotalBounties,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT v.Id) AS VoteCount
    FROM
        PostHierarchy ph
    LEFT JOIN LatestEdit l ON ph.PostId = l.PostId AND l.rn = 1
    LEFT JOIN UserActivity ua ON ph.PostId IN (SELECT ParentId FROM Posts WHERE ParentId IS NOT NULL)
    LEFT JOIN Comments c ON c.PostId = ph.PostId
    LEFT JOIN Votes v ON v.PostId = ph.PostId
    GROUP BY
        ph.PostId, ph.Title, ph.Depth, l.LastEditDate, l.EditorName, ua.TotalPosts, ua.TotalComments, ua.TotalBounties
)
SELECT
    ps.PostId,
    ps.Title,
    ps.Depth,
    ps.LastEditDate,
    ps.EditorName,
    ps.TotalPosts,
    ps.TotalComments,
    ps.TotalBounties,
    ps.CommentCount,
    ps.VoteCount,
    CASE
        WHEN ps.Depth > 1 THEN 'Nested Answer'
        ELSE 'Top Level Question'
    END AS PostType,
    CASE
        WHEN ps.VoteCount > 10 THEN 'Popular Post'
        ELSE 'Less Popular'
    END AS Popularity
FROM
    PostStatistics ps
WHERE
    ps.TotalPosts > 5 OR ps.CommentCount > 20
ORDER BY
    ps.TotalBounties DESC, ps.LastEditDate DESC;
