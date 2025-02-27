WITH RecursivePostHierarchy AS (
    -- Base case: Selecting all questions and their accepted answers
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.AcceptedAnswerId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1  -- Questions only

    UNION ALL

    -- Recursive case: Joining questions with their answers
    SELECT 
        p.Id AS QuestionId,
        p.Title,
        p.AcceptedAnswerId,
        rph.Level + 1 AS Level
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rph ON p.ParentId = rph.QuestionId
    WHERE p.PostTypeId = 2  -- Answers only
),

-- CTE to get user activity statistics
UserActivity AS (
    SELECT 
        u.Id AS UserId,
        u.DisplayName,
        COUNT(DISTINCT p.Id) AS TotalPosts,
        COUNT(DISTINCT c.Id) AS TotalComments,
        SUM(v.BountyAmount) AS TotalBounties
    FROM Users u
    LEFT JOIN Posts p ON p.OwnerUserId = u.Id
    LEFT JOIN Comments c ON c.UserId = u.Id
    LEFT JOIN Votes v ON v.UserId = u.Id
    GROUP BY u.Id
),

-- CTE to rank users based on their activity
RankedUsers AS (
    SELECT 
        UserId,
        DisplayName,
        TotalPosts,
        TotalComments,
        TotalBounties,
        RANK() OVER (ORDER BY TotalPosts DESC, TotalComments DESC) AS UserRank
    FROM UserActivity
)

-- Main query to get detailed post information with user ranking and activity data
SELECT 
    p.Id AS PostId,
    p.Title,
    p.Score,
    p.ViewCount,
    COALESCE(rph.Level, 0) AS AnswerLevel,
    u.DisplayName AS OwnerDisplayName,
    ru.UserRank,
    ru.TotalPosts,
    ru.TotalComments,
    ru.TotalBounties
FROM Posts p
LEFT JOIN RecursivePostHierarchy rph ON p AcceptedAnswerId = rph.QuestionId  -- Join with recursive CTE
LEFT JOIN Users u ON p.OwnerUserId = u.Id  -- Join to get post owner
LEFT JOIN RankedUsers ru ON u.Id = ru.UserId  -- Join to get user statistics
WHERE p.CreationDate >= DATEADD(MONTH, -6, GETDATE())  -- Only posts from the last 6 months
  AND (p.ContentLicense IS NULL OR p.ContentLicense <> 'CC BY-SA')  -- Filter out posts with specific content license
ORDER BY ru.UserRank, p.Score DESC;
