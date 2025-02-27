WITH RecursivePostHierarchy AS (
    -- CTE to recursively find all ancestors of a given post (if any)
    SELECT 
        Id,
        Title,
        ParentId,
        1 AS Level
    FROM Posts
    WHERE Id = (SELECT MIN(Id) FROM Posts WHERE PostTypeId = 1) -- Start from the oldest question

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM Posts p
    INNER JOIN RecursivePostHierarchy r ON p.Id = r.ParentId
),
PostStats AS (
    -- CTE to calculate some statistics for all questions
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.ViewCount,
        p.Score,
        COALESCE(AVG(voteScore), 0) AS AverageVoteScore,
        COUNT(DISTINCT c.Id) AS TotalComments,
        COUNT(DISTINCT b.Id) AS TotalBadgesEarned
    FROM Posts p
    LEFT JOIN Votes v ON p.Id = v.PostId AND v.VoteTypeId = 2 -- Upvotes
    LEFT JOIN Comments c ON p.Id = c.PostId
    LEFT JOIN Badges b ON p.OwnerUserId = b.UserId
    WHERE p.PostTypeId = 1 -- Only questions
    GROUP BY p.Id
),
TopQuestions AS (
    -- CTE to filter for top 10 questions based on score and view count
    SELECT 
        ps.Id,
        ps.Title,
        ps.CreationDate,
        ps.ViewCount,
        ps.Score,
        ps.AverageVoteScore,
        ps.TotalComments,
        ps.TotalBadgesEarned,
        ROW_NUMBER() OVER (ORDER BY ps.Score DESC, ps.ViewCount DESC) AS RN
    FROM PostStats ps
),
CommentsSummary AS (
    -- CTE for comments on top questions including user info
    SELECT 
        q.Id AS QuestionId,
        COUNT(c.Id) AS CommentCount,
        STRING_AGG(c.UserDisplayName, ', ') AS CommenterNames
    FROM TopQuestions q
    LEFT JOIN Comments c ON q.Id = c.PostId
    GROUP BY q.Id
)
SELECT 
    tq.Title,
    tq.CreationDate,
    tq.ViewCount,
    tq.Score,
    tq.AverageVoteScore,
    tq.TotalComments,
    tq.TotalBadgesEarned,
    cs.CommentCount,
    cs.CommenterNames,
    rh.Level AS PostHierarchyLevel,
    rh.Title AS ParentTitle
FROM TopQuestions tq
LEFT JOIN CommentsSummary cs ON tq.Id = cs.QuestionId
LEFT JOIN RecursivePostHierarchy rh ON tq.Id = rh.Id
WHERE tq.RN <= 10  -- Retrieve only the top 10 questions
ORDER BY tq.Score DESC;
