WITH RecursivePostHierarchy AS (
    -- CTE to retrieve the hierarchy of questions and answers
    SELECT 
        Id,
        Title,
        AcceptedAnswerId,
        ParentId,
        1 AS Level
    FROM 
        Posts
    WHERE 
        PostTypeId = 1   -- Get all questions
    UNION ALL
    SELECT 
        p.Id,
        p.Title,
        p.AcceptedAnswerId,
        p.ParentId,
        rp.Level + 1
    FROM 
        Posts p
    INNER JOIN 
        RecursivePostHierarchy rp ON p.ParentId = rp.Id
    WHERE 
        p.PostTypeId = 2  -- Get answers to the questions
), 

PostStats AS (
    -- CTE to aggregate statistics about posts and their votes
    SELECT 
        p.Id,
        p.Title,
        p.CreationDate,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVotes,
        COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVotes,
        COUNT(DISTINCT c.Id) AS CommentCount,
        COUNT(DISTINCT ph.Id) AS EditHistoryCount
    FROM 
        Posts p
    LEFT JOIN 
        Votes v ON p.Id = v.PostId
    LEFT JOIN 
        Comments c ON p.Id = c.PostId
    LEFT JOIN 
        PostHistory ph ON p.Id = ph.PostId
    GROUP BY 
        p.Id, p.Title, p.CreationDate
),

PostAggregate AS (
    -- CTE to aggregate the statistics for each post level
    SELECT 
        rp.Level,
        COUNT(p.Id) AS TotalPosts,
        SUM(ps.UpVotes) AS TotalUpVotes,
        SUM(ps.DownVotes) AS TotalDownVotes,
        SUM(ps.CommentCount) AS TotalComments,
        SUM(ps.EditHistoryCount) AS TotalEdits,
        AVG(EXTRACT(EPOCH FROM (CURRENT_TIMESTAMP - ps.CreationDate))) AS AvgAgeInSeconds
    FROM 
        RecursivePostHierarchy rp
    INNER JOIN 
        PostStats ps ON rp.Id = ps.Id
    GROUP BY 
        rp.Level
)

SELECT 
    pa.Level,
    pa.TotalPosts,
    pa.TotalUpVotes,
    pa.TotalDownVotes,
    pa.TotalComments,
    pa.TotalEdits,
    pa.AvgAgeInSeconds,
    CASE 
        WHEN pa.TotalPosts = 0 THEN 'No Data'
        ELSE CAST(pa.TotalUpVotes AS FLOAT) / NULLIF(pa.TotalPosts, 0) END AS AvgUpVotesPerPost,
    CASE 
        WHEN pa.TotalPosts = 0 THEN 'No Data'
        ELSE CAST(pa.TotalDownVotes AS FLOAT) / NULLIF(pa.TotalPosts, 0) END AS AvgDownVotesPerPost
FROM 
    PostAggregate pa
ORDER BY 
    pa.Level;
