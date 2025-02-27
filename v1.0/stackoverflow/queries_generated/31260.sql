WITH RecursivePostHierarchy AS (
    SELECT 
        Id,
        Title,
        OwnerUserId,
        ParentId,
        CreationDate,
        0 AS Level
    FROM 
        Posts
    WHERE 
        ParentId IS NULL  -- Top-level posts (Questions)
    
    UNION ALL
    
    SELECT 
        p.Id,
        p.Title,
        p.OwnerUserId,
        p.ParentId,
        p.CreationDate,
        r.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy r ON p.ParentId = r.Id  -- Linking child posts (Answers)
),

PostVoteStatistics AS (
    SELECT 
        PostId, 
        COUNT(CASE WHEN VoteTypeId = 2 THEN 1 END) AS UpVotes,
        COUNT(CASE WHEN VoteTypeId = 3 THEN 1 END) AS DownVotes,
        COUNT(CASE WHEN VoteTypeId = 1 THEN 1 END) AS AcceptedVotes
    FROM 
        Votes
    GROUP BY 
        PostId
),

PostsWithVotes AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.CreationDate,
        COALESCE(v.UpVotes, 0) AS UpVotes,
        COALESCE(v.DownVotes, 0) AS DownVotes,
        COALESCE(v.AcceptedVotes, 0) AS AcceptedVotes,
        r.Level
    FROM 
        Posts p
    LEFT JOIN 
        PostVoteStatistics v ON p.Id = v.PostId
    LEFT JOIN 
        RecursivePostHierarchy r ON p.Id = r.Id
)

SELECT 
    u.DisplayName AS OwnerDisplayName,
    p.PostId,
    p.Title,
    p.UpVotes,
    p.DownVotes,
    p.AcceptedVotes,
    r.Level,
    CASE 
        WHEN p.AcceptedVotes > 0 THEN 'Accepted'
        ELSE 'Not Accepted'
    END AS AcceptanceStatus,
    STRING_AGG(t.TagName, ', ') AS Tags
FROM 
    PostsWithVotes p
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    UNNEST(string_to_array(substring(p.Tags, 2, length(p.Tags)-2), '><')) AS tagname ON TRUE
JOIN 
    Tags t ON t.TagName = tagname
WHERE 
    p.UpVotes > p.DownVotes
GROUP BY 
    u.DisplayName, p.PostId, p.Title, p.UpVotes, p.DownVotes, p.AcceptedVotes, r.Level
ORDER BY 
    r.Level, p.UpVotes DESC;

This SQL query performs a series of complex operations including recursive Common Table Expressions (CTEs), aggregation with window functions, and conditional logic. It retrieves posts, their associated vote counts, filters to show only posts with more upvotes than downvotes, and categorizes them based on acceptance status. The recursive CTE builds a hierarchy showing parent-child relationships for posts, while aggregating tags dynamically. This ensures a comprehensive analysis of post performances suitable for benchmarking.
