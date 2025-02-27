WITH RecursivePostHierarchy AS (
    SELECT 
        Id AS PostId,
        ParentId,
        Title,
        0 AS Level
    FROM Posts
    WHERE ParentId IS NULL

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.Title,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserEngagement AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(COALESCE(vt.Id = 2, 0)) AS TotalUpvotes,
        SUM(COALESCE(vt.Id = 3, 0)) AS TotalDownvotes,
        SUM(CASE WHEN vt.Id = 1 THEN 1 ELSE 0 END) AS AcceptedAnswers
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON p.Id = v.PostId
    LEFT JOIN VoteTypes vt ON v.VoteTypeId = vt.Id
    GROUP BY u.Id, u.DisplayName
),
PopularTags AS (
    SELECT 
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(p.Tags, ',')::int[])
    GROUP BY t.TagName
    HAVING COUNT(p.Id) > 5
),
ClosedPosts AS (
    SELECT 
        p.Id,
        p.Title,
        ph.CreationDate,
        ph.UserId,
        ph.Comment AS CloseReason
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    WHERE ph.PostHistoryTypeId = 10
)
SELECT 
    ue.UserId,
    ue.DisplayName,
    ue.TotalPosts,
    ue.TotalUpvotes,
    ue.TotalDownvotes,
    ue.AcceptedAnswers,
    pt.TagName,
    pt.PostCount,
    rp.Level AS PostHierarchyLevel,
    cp.Title AS ClosedPostTitle,
    cp.CloseReason
FROM UserEngagement ue
LEFT JOIN PopularTags pt ON pt.PostCount > 10
LEFT JOIN RecursivePostHierarchy rp ON ue.TotalPosts > 0
LEFT JOIN ClosedPosts cp ON ue.UserId = cp.UserId
ORDER BY ue.TotalPosts DESC, ue.TotalUpvotes DESC, pt.PostCount DESC;
