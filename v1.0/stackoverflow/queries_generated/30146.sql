WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        ParentId,
        0 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1  -- Questions

    UNION ALL

    SELECT 
        p.Id,
        p.Title,
        p.ParentId,
        Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id
),
UserVoteStatistics AS (
    SELECT 
        UserId,
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS TotalUpvotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS TotalDownvotes
    FROM 
        Votes
    GROUP BY 
        UserId
),
PostMetric AS (
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        p.Score,
        COALESCE(SUM(CASE WHEN c.Id IS NOT NULL THEN 1 END), 0) AS TotalComments,
        COALESCE(SUM(CASE WHEN ph.PostId IS NOT NULL THEN 1 END), 0) AS TotalHistoryEntries
    FROM 
        Posts p
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate, p.Score
),
PostDetails AS (
    SELECT 
        p.Id,
        p.Title,
        u.DisplayName AS Owner,
        ps.TotalUpvotes,
        ps.TotalDownvotes,
        pm.TotalComments,
        pm.TotalHistoryEntries,
        p.CreationDate
    FROM 
        Posts p
    JOIN 
        Users u ON p.OwnerUserId = u.Id
    LEFT JOIN 
        UserVoteStatistics ps ON u.Id = ps.UserId
    JOIN 
        PostMetric pm ON p.Id = pm.Id
)
SELECT 
    p.Id,
    p.Title,
    p.Owner,
    p.CreationDate,
    p.TotalComments,
    p.TotalHistoryEntries,
    CONCAT('Upvotes: ', COALESCE(p.TotalUpvotes, 0), ', Downvotes: ', COALESCE(p.TotalDownvotes, 0)) AS VoteSummary,
    RECURSIVE_PATH.Path
FROM 
    PostDetails p
CROSS JOIN LATERAL (
    SELECT 
        STRING_AGG(r.Title, ' -> ') AS Path
    FROM 
        RecursivePostHierarchy r 
    WHERE 
        r.Id = p.Id OR r.Id = p.Id  -- To include the post itself in the path
) AS RECURSIVE_PATH
ORDER BY 
    p.CreationDate DESC
LIMIT 100 OFFSET 0;
