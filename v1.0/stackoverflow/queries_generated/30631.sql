WITH RecursivePostCTE AS (
    SELECT 
        p.Id AS PostId,
        p.Title,
        p.OwnerUserId,
        p.CreationDate,
        p.AcceptedAnswerId,
        1 AS Level
    FROM 
        Posts p
    WHERE 
        p.PostTypeId = 1  -- Only Questions
    
    UNION ALL
    
    SELECT 
        p2.Id,
        p2.Title,
        p2.OwnerUserId,
        p2.CreationDate,
        p2.AcceptedAnswerId,
        Level + 1
    FROM 
        Posts p2
    INNER JOIN 
        RecursivePostCTE r ON p2.ParentId = r.PostId
)

SELECT 
    r.PostId,
    r.Title,
    u.DisplayName AS Author,
    COUNT(DISTINCT c.Id) AS CommentCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 2 THEN 1 ELSE 0 END), 0) AS UpVoteCount,
    COALESCE(SUM(CASE WHEN v.VoteTypeId = 3 THEN 1 ELSE 0 END), 0) AS DownVoteCount,
    r.Level,
    RANK() OVER (PARTITION BY r.Level ORDER BY COALESCE(SUM(v.VoteTypeId), 0) DESC) AS RankByPopularity

FROM 
    RecursivePostCTE r
LEFT JOIN 
    Users u ON r.OwnerUserId = u.Id
LEFT JOIN 
    Comments c ON r.PostId = c.PostId
LEFT JOIN 
    Votes v ON r.PostId = v.PostId

GROUP BY 
    r.PostId, r.Title, u.DisplayName, r.Level

ORDER BY 
    r.Level, RankByPopularity;
