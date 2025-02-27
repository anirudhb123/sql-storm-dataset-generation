WITH RecursivePostHierarchy AS (
    -- CTE to get the hierarchy of posts (questions and answers)
    SELECT
        Id AS PostId,
        Title,
        ParentId,
        0 AS Level
    FROM Posts
    WHERE PostTypeId = 1 -- Questions

    UNION ALL

    SELECT
        a.Id AS PostId,
        a.Title,
        a.ParentId,
        Level + 1
    FROM Posts a
    JOIN RecursivePostHierarchy q ON a.ParentId = q.PostId
    WHERE a.PostTypeId = 2 -- Answers
),
UserStatistics AS (
    -- CTE to calculate user statistics
    SELECT
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        SUM(CASE WHEN p.PostTypeId = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
        SUM(CASE WHEN p.PostTypeId = 2 THEN 1 ELSE 0 END) AS TotalAnswers,
        COALESCE(SUM(v.BountyAmount), 0) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON u.Id = p.OwnerUserId
    LEFT JOIN Votes v ON u.Id = v.UserId
    GROUP BY u.Id
),
TopTags AS (
    -- CTE to get the top tags based on post count
    SELECT
        t.TagName,
        COUNT(p.Id) AS PostCount
    FROM Tags t
    JOIN Posts p ON t.Id = ANY(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')::int[])
    GROUP BY t.TagName
    ORDER BY PostCount DESC
    LIMIT 10
),
ClosedPosts AS (
    -- CTE to get closed posts along with close reason details
    SELECT 
        p.Id AS PostId,
        p.Title,
        phd.Text AS CloseReason,
        ph.CreationDate AS ClosedDate
    FROM Posts p
    JOIN PostHistory ph ON p.Id = ph.PostId
    JOIN PostHistoryTypes pht ON ph.PostHistoryTypeId = pht.Id
    WHERE pht.Name = 'Post Closed'
),
RecentActivity AS (
    -- CTE to get recent activity of each post
    SELECT
        p.Id AS PostId,
        p.Title,
        COALESCE(MAX(c.CreationDate), p.CreationDate) AS RecentActivityDate,
        COUNT(c.Id) AS CommentCount,
        COUNT(DISTINCT ph.UserId) AS EditCount
    FROM Posts p
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN PostHistory ph ON p.Id = ph.PostId
    GROUP BY p.Id
)
SELECT
    u.DisplayName AS User,
    us.TotalPosts,
    us.TotalQuestions,
    us.TotalAnswers,
    us.TotalBounties,
    rph.PostId AS QuestionId,
    rph.Title AS QuestionTitle,
    rph.Level,
    tp.TagName AS TopTag,
    cp.CloseReason,
    cp.ClosedDate,
    ra.RecentActivityDate,
    ra.CommentCount,
    ra.EditCount
FROM UserStatistics us
JOIN RecursivePostHierarchy rph ON us.TotalQuestions > 0 
LEFT JOIN TopTags tp ON true -- Cross join to associate users with top tags
LEFT JOIN ClosedPosts cp ON rph.PostId = cp.PostId
LEFT JOIN RecentActivity ra ON rph.PostId = ra.PostId
WHERE us.TotalBounties > 0
ORDER BY us.TotalBounties DESC, us.TotalPosts DESC, rph.Level;
