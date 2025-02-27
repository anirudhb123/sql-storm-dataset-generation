WITH RecursivePostHierarchy AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.AcceptedAnswerId,
        p.CreationDate,
        0 AS Level,
        CAST(p.Title AS VARCHAR(MAX)) AS Path
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1 -- Questions only
    
    UNION ALL
    
    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.AcceptedAnswerId,
        p2.CreationDate,
        r.Level + 1,
        CAST(r.Path + ' -> ' + p2.Title AS VARCHAR(MAX))
    FROM 
        Posts p2
    JOIN 
        RecursivePostHierarchy r ON r.PostId = p2.ParentId
    WHERE 
        p2.PostTypeId = 2 -- Answers only
),
PostStatistics AS (
    SELECT 
        p.Id,
        p.Title,
        COALESCE(uh.TotalVotes, 0) AS TotalVotes,
        COALESCE(ch.CommentCount, 0) AS TotalComments,
        COALESCE(hh.HistoryCount, 0) AS HistoryChanges
    FROM 
        Posts p
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS TotalVotes
        FROM 
            Votes
        GROUP BY 
            PostId
    ) uh ON p.Id = uh.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS CommentCount
        FROM 
            Comments
        GROUP BY 
            PostId
    ) ch ON p.Id = ch.PostId
    LEFT JOIN (
        SELECT 
            PostId, COUNT(*) AS HistoryCount
        FROM 
            PostHistory
        GROUP BY 
            PostId
    ) hh ON p.Id = hh.PostId
)
SELECT 
    p.Id,
    p.Title,
    u.DisplayName AS Owner,
    ps.TotalVotes,
    ps.TotalComments,
    ps.HistoryChanges,
    r.Path,
    ROW_NUMBER() OVER (PARTITION BY u.Id ORDER BY ps.TotalVotes DESC) AS RankByVotes,
    DENSE_RANK() OVER (ORDER BY ps.TotalVotes DESC) AS VoteRankGlobal
FROM 
    PostStatistics ps
JOIN 
    Posts p ON ps.Id = p.Id
JOIN 
    Users u ON p.OwnerUserId = u.Id
LEFT JOIN 
    RecursivePostHierarchy r ON p.Id = r.PostId
WHERE 
    ps.TotalVotes > 0
ORDER BY 
    ps.TotalVotes DESC, 
    ps.TotalComments DESC;
