WITH RecursivePostHierarchy AS (
    -- Recursive Common Table Expression to find all descendants of questions
    SELECT
        p.Id AS PostId,
        COALESCE(p.Title, 'Untitled') AS Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        0 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Starting from questions (PostTypeId = 1)

    UNION ALL

    SELECT
        p.Id AS PostId,
        COALESCE(p.Title, 'Untitled') AS Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId  -- Get answers or comments to the questions
),

UserActivity AS (
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        SUM(COALESCE(p.ViewCount, 0)) AS TotalViews,
        SUM(COALESCE(v.BountyAmount, 0)) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id, u.DisplayName
),

LatestEdits AS (
    SELECT
        p.Id AS PostId,
        p.LastEditDate,
        u.DisplayName AS LastEditor,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY p.LastEditDate DESC) AS rn
    FROM Posts p
    INNER JOIN Users u ON p.LastEditorUserId = u.Id
)

SELECT
    r.PostId,
    r.Title,
    COALESCE(u.DisplayName, 'Unknown') AS Author,
    r.CreationDate,
    r.AcceptedAnswerId,
    r.Level,
    u.TotalViews,
    u.TotalBounties,
    le.LastEditDate,
    le.LastEditor
FROM RecursivePostHierarchy r
LEFT JOIN Users u ON r.OwnerUserId = u.Id
LEFT JOIN UserActivity ua ON u.Id = ua.UserId
LEFT JOIN LatestEdits le ON r.PostId = le.PostId AND le.rn = 1
WHERE r.Level > 0  -- Exclude the top-level questions
ORDER BY u.TotalViews DESC, r.CreationDate DESC
LIMIT 100;  -- Limit the results for better performance benchmarking

