WITH RecursivePostHierarchy AS (
    -- CTE to get the hierarchy of posts and their accepted answers
    SELECT 
        p.Id AS PostId, 
        p.Title, 
        p.AcceptedAnswerId, 
        0 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1   -- Only questions

    UNION ALL

    SELECT 
        p.Id, 
        p.Title, 
        p.AcceptedAnswerId, 
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.PostId
),
UserActivity AS (
    -- CTE to gather user activities: votes, comments and badges 
    SELECT 
        u.Id AS UserId,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS Upvotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS Downvotes,
        COALESCE(COUNT(c.Id), 0) AS CommentCount,
        COALESCE(COUNT(b.Id), 0) AS BadgeCount
    FROM 
        Users u
    LEFT JOIN 
        Votes v ON u.Id = v.UserId
    LEFT JOIN 
        Comments c ON u.Id = c.UserId
    LEFT JOIN 
        Badges b ON u.Id = b.UserId
    GROUP BY 
        u.Id
),
PostMetrics AS (
    -- CTE to calculate metrics for posts, including average score
    SELECT 
        p.Id AS PostId,
        p.Title,
        COUNT(DISTINCT c.Id) AS TotalComments,
        AVG(p.Score) OVER() AS AverageScore,
        COUNT(DISTINCT v.Id) AS TotalVotes
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    GROUP BY 
        p.Id
)
SELECT 
    p.PostId,
    p.Title,
    pm.TotalComments,
    pm.AverageScore,
    pm.TotalVotes,
    r.AcceptedAnswerId,
    u.UserId,
    u.Upvotes,
    u.Downvotes,
    u.CommentCount AS UserCommentCount,
    u.BadgeCount,
    CASE 
        WHEN pm.TotalVotes = 0 THEN 'No votes yet'
        WHEN pm.TotalVotes > 100 THEN 'Popular'
        ELSE 'Moderate interest'
    END AS PostInterestLevel
FROM 
    RecursivePostHierarchy r
JOIN 
    PostMetrics pm ON r.PostId = pm.PostId
JOIN 
    UserActivity u ON r.PostId IN (SELECT AcceptedAnswerId FROM Posts WHERE AcceptedAnswerId IS NOT NULL)
WHERE 
    pm.AverageScore > 0  -- Only show posts with positive average score
ORDER BY 
    pm.AverageScore DESC,  -- Show higher scores first
    pm.TotalComments DESC;  -- Then by comments
