WITH RecursivePostHierarchy AS (
    -- Recursive CTE to find all answers to questions and their respective user interactions
    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.OwnerUserId,
        1 AS Level
    FROM Posts p
    WHERE p.PostTypeId = 1 -- Questions

    UNION ALL

    SELECT 
        p.Id AS PostId,
        p.ParentId,
        p.OwnerUserId,
        rp.Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy rp ON p.ParentId = rp.PostId
    WHERE p.PostTypeId = 2 -- Answers
),
VotesSummary AS (
    -- Summarizing upvotes and downvotes for posts
    SELECT 
        PostId,
        SUM(CASE WHEN VoteTypeId = 2 THEN 1 ELSE 0 END) AS UpVotes,
        SUM(CASE WHEN VoteTypeId = 3 THEN 1 ELSE 0 END) AS DownVotes
    FROM Votes
    GROUP BY PostId
),
ActiveUsers AS (
    -- Finding active users based on their activity
    SELECT 
        UserId,
        COUNT(*) AS PostsCount
    FROM Posts
    WHERE CreationDate >= NOW() - INTERVAL '30 days'
    GROUP BY UserId
    HAVING COUNT(*) > 5 -- Users with more than 5 posts in the last 30 days
)
SELECT
    u.Id AS UserId,
    u.DisplayName,
    u.Reputation,
    COALESCE(vs.UpVotes, 0) AS TotalUpVotes,
    COALESCE(vs.DownVotes, 0) AS TotalDownVotes,
    COUNT(DISTINCT rp.PostId) AS TotalPosts,
    SUM(CASE WHEN rp.Level = 1 THEN 1 ELSE 0 END) AS TotalQuestions,
    SUM(CASE WHEN rp.Level > 1 THEN 1 ELSE 0 END) AS TotalAnswers
FROM Users u
LEFT JOIN RecursivePostHierarchy rp ON u.Id = rp.OwnerUserId
LEFT JOIN VotesSummary vs ON rp.PostId = vs.PostId
WHERE u.Reputation > 100
AND u.LastAccessDate >= NOW() - INTERVAL '14 days'
AND EXISTS (SELECT 1 FROM ActiveUsers au WHERE au.UserId = u.Id)
GROUP BY u.Id, u.DisplayName, u.Reputation
ORDER BY TotalUpVotes DESC, TotalPosts DESC
LIMIT 10;
